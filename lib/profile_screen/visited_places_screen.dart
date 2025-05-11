import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

class VisitedPlacesScreen extends StatefulWidget {
  const VisitedPlacesScreen({super.key});

  @override
  State<VisitedPlacesScreen> createState() => _VisitedPlacesScreenState();
}

class _VisitedPlacesScreenState extends State<VisitedPlacesScreen> {
  final TextEditingController _placeController = TextEditingController();
  DateTime? _selectedDate;
  User? _currentUser;
  late Future<void> _userInitFuture;
  bool _isAddingPlace = false;

  @override
  void initState() {
    super.initState();
    _userInitFuture = _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Khởi tạo Firebase thất bại: $e');
    }

    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      debugPrint('UID người dùng đã xác thực: ${_currentUser!.uid}');
      final userDoc = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      final snapshot = await userDoc.get();
      if (!snapshot.exists) {
        try {
          await userDoc.set({
            'createdAt': FieldValue.serverTimestamp(),
            'email': _currentUser!.email ?? '',
          });
          debugPrint('Tài liệu người dùng đã được tạo cho UID: ${_currentUser!.uid}');
        } catch (e) {
          debugPrint('Không thể tạo tài liệu người dùng: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không thể tạo dữ liệu người dùng: $e')),
            );
          }
        }
      }
    } else {
      debugPrint('Không tìm thấy người dùng đã xác thực');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn cần đăng nhập để tiếp tục')),
        );
      }
    }
  }

  CollectionReference<Map<String, dynamic>> get _placesCollection {
    if (_currentUser == null) {
      throw Exception('Người dùng chưa được xác thực');
    }
    return FirebaseFirestore.instance.collection('visited_places');
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _addPlace() async {
    if (_isAddingPlace) return;
    final place = _placeController.text.trim();
    if (place.isEmpty || _selectedDate == null || _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên và chọn ngày')),
      );
      return;
    }

    setState(() => _isAddingPlace = true);
    try {
      final data = {
        'name': place,
        'visitDate': Timestamp.fromDate(_selectedDate!),
        'userId': _currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      };
      debugPrint('Đang thử ghi vào Firestore tại: visited_places');
      debugPrint('Dữ liệu: $data');
      await _placesCollection.add(data);
      debugPrint('Đã thêm địa điểm thành công vào Firestore');

      final snapshot = await _placesCollection
          .where('name', isEqualTo: place)
          .where('visitDate', isEqualTo: Timestamp.fromDate(_selectedDate!))
          .where('userId', isEqualTo: _currentUser!.uid)
          .get();
      if (snapshot.docs.isNotEmpty) {
        debugPrint('Dữ liệu đã được xác nhận trên Firestore');
      } else {
        debugPrint('Dữ liệu chưa được đồng bộ lên Firestore (có thể đang ngoại tuyến)');
      }

      _placeController.clear();
      setState(() => _selectedDate = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm địa điểm thành công')),
      );
    } catch (e) {
      debugPrint('Không thể thêm địa điểm: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu địa điểm: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingPlace = false);
      }
    }
  }

  Future<void> _deletePlace(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn muốn xoá địa điểm "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        // Kiểm tra tài liệu trước khi xóa
        final docSnapshot = await _placesCollection.doc(docId).get();
        if (!docSnapshot.exists) {
          throw Exception('Tài liệu không tồn tại');
        }
        final data = docSnapshot.data();
        if (data == null || !data.containsKey('userId')) {
          throw Exception('Tài liệu không có trường userId');
        }
        if (data['userId'] != _currentUser!.uid) {
          throw Exception('Bạn không có quyền xóa tài liệu này (userId không khớp)');
        }

        await _placesCollection.doc(docId).delete();
        debugPrint('Đã xóa địa điểm: $docId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xoá địa điểm thành công')),
        );
      } catch (e) {
        debugPrint('Không thể xoá địa điểm: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xoá: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
        : 'Ngày đã đi';

    return FutureBuilder(
      future: _userInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_currentUser == null) {
          return const Scaffold(
            body: Center(child: Text("Bạn cần đăng nhập để xem địa điểm.")),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: const Text('Nơi đã đến'),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      controller: _placeController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tên địa điểm...',
                        prefixIcon: const Icon(Icons.place_outlined),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(dateText),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              foregroundColor: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _isAddingPlace ? null : _addPlace,
                          icon: _isAddingPlace
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.add),
                          label: _isAddingPlace
                              ? const Text('Đang thêm...')
                              : const Text('Thêm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _placesCollection.orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      debugPrint('Lỗi StreamBuilder: ${snapshot.error}');
                      return Center(
                        child: Text('Lỗi khi tải dữ liệu: ${snapshot.error}'),
                      );
                    }

                    final places = snapshot.data?.docs ?? [];

                    if (places.isEmpty) {
                      return const Center(
                        child: Text('Chưa có địa điểm nào.', style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: places.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final doc = places[index];
                        final name = doc['name'] ?? '';
                        final visitTimestamp = doc.data().containsKey('visitDate')
                            ? doc['visitDate'] as Timestamp?
                            : null;
                        final visitDate = visitTimestamp != null
                            ? DateFormat('dd/MM/yyyy').format(visitTimestamp.toDate())
                            : 'Không có ngày';

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.location_on, color: Colors.blueAccent),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Ngày đi: $visitDate'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deletePlace(doc.id, name),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }
}