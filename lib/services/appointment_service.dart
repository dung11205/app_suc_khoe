import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isUserLoggedIn => currentUser != null;

  CollectionReference<Map<String, dynamic>> get appointmentsCollection =>
      _firestore.collection('appointments');

  // Tạo lịch hẹn mới
  Future<void> createAppointment({
    required String doctorName,
    required String symptoms,
    required DateTime appointmentDate,
    required BuildContext context,
  }) async {
    if (!isUserLoggedIn) {
      showSnack(context, 'Bạn cần đăng nhập để đặt lịch hẹn');
      return;
    }

    try {
      await appointmentsCollection.add({
        'userId': currentUser!.uid,
        'doctorName': doctorName.trim(),
        'symptoms': symptoms.trim(),
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'timestamp': Timestamp.now(),
      });
      debugPrint("Created appointment with date: $appointmentDate (UTC: ${appointmentDate.toUtc()})");
      showSnack(context, 'Đặt lịch khám thành công');
    } catch (e) {
      debugPrint("Error creating appointment: $e");
      showSnack(context, 'Lỗi khi đặt lịch: ${e.toString()}');
    }
  }

  // Xóa lịch hẹn
  Future<void> deleteAppointment({
    required String docId,
    required BuildContext context,
  }) async {
    if (!isUserLoggedIn) {
      showSnack(context, 'Bạn cần đăng nhập');
      return;
    }

    try {
      final doc = await appointmentsCollection.doc(docId).get();
      if (!doc.exists) {
        throw Exception('Lịch hẹn không tồn tại');
      }

      final data = doc.data();
      if (data?['userId'] != currentUser!.uid) {
        throw Exception('Không có quyền xóa lịch hẹn này');
      }

      await appointmentsCollection.doc(docId).delete();
      showSnack(context, 'Đã xóa lịch hẹn thành công');
    } catch (e) {
      debugPrint("Error deleting appointment: $e");
      showSnack(context, 'Không thể xóa: ${e.toString()}');
    }
  }

  // Cập nhật lịch hẹn
  Future<void> updateAppointment({
    required String docId,
    required String doctorName,
    required String symptoms,
    required DateTime appointmentDate,
    required BuildContext context,
  }) async {
    if (!isUserLoggedIn) {
      showSnack(context, 'Bạn cần đăng nhập');
      return;
    }

    try {
      final doc = await appointmentsCollection.doc(docId).get();
      if (!doc.exists) {
        throw Exception('Lịch hẹn không tồn tại');
      }

      final data = doc.data();
      if (data?['userId'] != currentUser!.uid) {
        throw Exception('Không có quyền sửa lịch hẹn này');
      }

      await appointmentsCollection.doc(docId).update({
        'doctorName': doctorName.trim(),
        'symptoms': symptoms.trim(),
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'updatedAt': Timestamp.now(),
      });
      debugPrint("Updated appointment with date: $appointmentDate (UTC: ${appointmentDate.toUtc()})");
      showSnack(context, 'Cập nhật lịch thành công');
    } catch (e) {
      debugPrint("Error updating appointment: $e");
      showSnack(context, 'Lỗi khi cập nhật: ${e.toString()}');
    }
  }

  // Lấy stream lịch hẹn sắp tới
  Stream<QuerySnapshot<Map<String, dynamic>>> getCurrentAppointmentsStream() {
    if (!isUserLoggedIn) {
      debugPrint("User not logged in, returning empty stream");
      return const Stream.empty();
    }
    // Chuyển thời gian hiện tại về UTC để đồng bộ với Firestore
    final now = Timestamp.fromDate(DateTime.now().toUtc());
    final userId = currentUser!.uid;

    debugPrint("Fetching current appointments for user: $userId, after: ${DateTime.now().toUtc()}");
    return appointmentsCollection
        .where('userId', isEqualTo: userId)
        .where('appointmentDate', isGreaterThan: now)
        .orderBy('appointmentDate')
        .snapshots()
        .handleError((error) {
      debugPrint("Error fetching current appointments: $error");
    });
  }

  // Lấy stream lịch sử khám
  Stream<QuerySnapshot<Map<String, dynamic>>> getAppointmentHistoryStream() {
    if (!isUserLoggedIn) {
      debugPrint("User not logged in, returning empty stream");
      return const Stream.empty();
    }
    final now = Timestamp.fromDate(DateTime.now().toUtc());
    final userId = currentUser!.uid;

    debugPrint("Fetching history for user: $userId, before: ${DateTime.now().toUtc()}");
    return appointmentsCollection
        .where('userId', isEqualTo: userId)
        .where('appointmentDate', isLessThanOrEqualTo: now)
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .handleError((error) {
      debugPrint("Error fetching appointment history: $error");
    });
  }

  // Lấy tất cả lịch hẹn (cho admin)
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllAppointments() {
    debugPrint("Fetching all appointments");
    return appointmentsCollection
        .orderBy('appointmentDate')
        .snapshots()
        .handleError((error) {
      debugPrint("Error fetching all appointments: $error");
    });
  }

  // Lấy tất cả lịch hẹn của người dùng (không phân biệt lịch sử hay sắp tới)
  Stream<QuerySnapshot<Map<String, dynamic>>> getAppointments() {
    if (!isUserLoggedIn) {
      debugPrint("User not logged in, returning empty stream");
      return const Stream.empty();
    }
    final userId = currentUser!.uid;

    debugPrint("Fetching all appointments for user: $userId");
    return appointmentsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .handleError((error) {
      debugPrint("Error fetching all appointments: $error");
    });
  }

  // Hiển thị thông báo (public method)
  void showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}