import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/health_entry.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Thêm mục sức khỏe
  Future<void> addHealthEntry(HealthEntry entry) async {
    try {
      await _db
          .collection('health_entries')
          .doc(entry.id)
          .set(entry.toMap());
    } catch (e) {
      throw Exception('Lỗi thêm mục sức khỏe: $e');
    }
  }

  // Alias cho add_entry_screen.dart
  Future<void> addEntry(HealthEntry entry) => addHealthEntry(entry);

  // Cập nhật mục sức khỏe
  Future<void> updateHealthEntry(HealthEntry entry) async {
    try {
      await _db
          .collection('health_entries')
          .doc(entry.id)
          .update(entry.toMap());
    } catch (e) {
      throw Exception('Lỗi cập nhật mục sức khỏe: $e');
    }
  }

  // Xóa mục sức khỏe
  Future<void> deleteHealthEntry(String id) async {
    try {
      await _db.collection('health_entries').doc(id).delete();
    } catch (e) {
      throw Exception('Lỗi xóa mục sức khỏe: $e');
    }
  }

  // Lấy danh sách mục sức khỏe theo userId
  Stream<List<HealthEntry>> getHealthEntries(String userId) {
    return _db
        .collection('health_entries')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthEntry.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Alias cho chart_screen.dart
  Stream<List<HealthEntry>> getEntries() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    return getHealthEntries(userId);
  }
}