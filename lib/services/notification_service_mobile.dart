import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _notifications = [];
  String? currentUserId;
  String? token;

  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);

  Future<void> initialize({required String userId}) async {
    currentUserId = userId;

    token = await _messaging.getToken();
    if (token != null) {
      await _saveDeviceToken(userId, token!);
    }

    await _messaging.subscribeToTopic('all');

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleForegroundMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage?.notification != null) {
      await _handleForegroundMessage(initialMessage!);
    }

    await loadNotificationHistory(userId);
  }

  Future<void> _saveDeviceToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  Future<void> loadNotificationHistory(String userId) async {
    final snap = await _firestore
        .collection('notifications')
        .doc('user_$userId')
        .collection('items')
        .orderBy('timestamp', descending: true)
        .get();

    _notifications = snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    notifyListeners();
  }

  Future<void> _handleForegroundMessage(RemoteMessage msg) async {
    final notif = msg.notification;
    if (notif == null || currentUserId == null) return;

    final newNoti = {
      'title': notif.title,
      'body': notif.body,
      'timestamp': Timestamp.now(),
      'read': false,
    };

    await saveNotification(newNoti);
    await loadNotificationHistory(currentUserId!);
  }

  Future<void> markAsRead(String id) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('notifications')
        .doc('user_$currentUserId')
        .collection('items')
        .doc(id)
        .update({'read': true});
    final idx = _notifications.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      _notifications[idx]['read'] = true;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('notifications')
        .doc('user_$currentUserId')
        .collection('items')
        .doc(id)
        .delete();
    _notifications.removeWhere((n) => n['id'] == id);
    notifyListeners();
  }

  Future<void> saveNotification(Map<String, Object?> newNoti) async {
    if (currentUserId == null) return;
    final docRef = await _firestore
        .collection('notifications')
        .doc('user_$currentUserId')
        .collection('items')
        .add(newNoti);
    newNoti['id'] = docRef.id;
    _notifications.insert(0, newNoti);
    notifyListeners();
  }
}
