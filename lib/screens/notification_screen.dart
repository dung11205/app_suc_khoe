import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_apps/services/notification_service.dart';

class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      final service = Provider.of<NotificationService>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('Người dùng chưa đăng nhập!');
        return;
      }

      await service.initialize(userId: user.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = context.watch<NotificationService>();
    final notifications = notificationService.notifications;

    return ScrollConfiguration(
      behavior: NoScrollbarBehavior(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thông báo đã nhận'),
          centerTitle: true,
          elevation: 0,
        ),
        body: notifications.isEmpty
            ? const Center(child: Text('Chưa có thông báo nào'))
            : RefreshIndicator(
                onRefresh: () async {
                  if (notificationService.currentUserId != null) {
                    await notificationService.loadNotificationHistory(
                      notificationService.currentUserId!,
                    );
                  }
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final noti = notifications[index];
                    final timestamp = (noti['timestamp'] as Timestamp).toDate();
                    final id = noti['id'] as String;

                    return Dismissible(
                      key: ValueKey(id),
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _deleteNotification(notificationService, id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: Icon(
                              Icons.notifications,
                              color: noti['read'] == false ? Colors.red : Colors.grey,
                            ),
                            title: Text(
                              noti['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  noti['body'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${timestamp.day}/${timestamp.month}/${timestamp.year} '
                                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (noti['read'] == false) {
                                _markAsRead(notificationService, id);
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _markAsRead(NotificationService service, String notificationId) async {
    await service.markAsRead(notificationId);
  }

  Future<void> _deleteNotification(NotificationService service, String notificationId) async {
    await service.deleteNotification(notificationId);
  }
}