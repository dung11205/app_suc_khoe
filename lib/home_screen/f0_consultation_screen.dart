import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/ai_service.dart';

class F0ConsultationScreen extends StatefulWidget {
  const F0ConsultationScreen({super.key});

  @override
  State<F0ConsultationScreen> createState() => _F0ConsultationScreenState();
}

class _F0ConsultationScreenState extends State<F0ConsultationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startNewChat();
  }

  Future<void> _startNewChat() async {
    final user = FirebaseAuth.instance.currentUser;
    print('User UID in _startNewChat: ${user?.uid}');
    if (user == null) {
      print('Người dùng chưa đăng nhập');
      setState(() {
        _messages.clear();
        _messages.add({
          'sender': 'bot',
          'message': 'Vui lòng đăng nhập để tiếp tục.',
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
      return;
    }

    // Tạo một document mới cho phiên chat
    final chatRef = await FirebaseFirestore.instance.collection('f0_consultations').add({
      'userId': user.uid,
      'createdAt': DateTime.now().toIso8601String(),
    });

    try {
      final defaultBotMessage = {
        'sender': 'bot',
        'message': 'Tôi có thể giúp gì cho bạn?',
        'timestamp': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'chatId': chatRef.id, // Gắn chatId để liên kết tin nhắn với phiên
      };

      final docRef = await FirebaseFirestore.instance
          .collection('f0_consultations')
          .doc(chatRef.id)
          .collection('messages')
          .add(defaultBotMessage);
      print('Tin nhắn mặc định đã được lưu với ID: ${docRef.id}');

      setState(() {
        _messages.clear();
        _messages.add(defaultBotMessage);
      });
    } catch (e) {
      print('Lỗi khi khởi tạo chat mới: $e');
      setState(() {
        _messages.clear();
        _messages.add({
          'sender': 'bot',
          'message': 'Xin lỗi, có lỗi xảy ra khi khởi tạo chat.',
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    print('User UID in _sendMessage: ${user?.uid}');
    if (user == null) {
      print('Người dùng chưa đăng nhập');
      setState(() {
        _messages.add({
          'sender': 'bot',
          'message': 'Vui lòng đăng nhập để tiếp tục.',
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
      return;
    }

    // Lấy chatId của phiên chat hiện tại (giả sử chatId được lưu từ _startNewChat)
    String? chatId;
    if (_messages.isNotEmpty) {
      chatId = _messages.first['chatId'] as String?;
    }
    if (chatId == null) {
      print('Không tìm thấy chatId, khởi tạo lại chat');
      await _startNewChat();
      chatId = _messages.first['chatId'] as String?;
    }

    final userMessage = {
      'sender': 'user',
      'message': text,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': user.uid,
      'chatId': chatId,
    };

    try {
      final userDocRef = await FirebaseFirestore.instance
          .collection('f0_consultations')
          .doc(chatId)
          .collection('messages')
          .add(userMessage);
      print('Tin nhắn người dùng đã được lưu với ID: ${userDocRef.id}');

      setState(() {
        _messages.add(userMessage);
        _messageController.clear();
        _isLoading = true;
      });

      try {
        final replyText = await AIService.getGPTReply(text);

        final botMessage = {
          'sender': 'bot',
          'message': replyText,
          'timestamp': DateTime.now().toIso8601String(),
          'userId': user.uid,
          'chatId': chatId,
        };

        final botDocRef = await FirebaseFirestore.instance
            .collection('f0_consultations')
            .doc(chatId)
            .collection('messages')
            .add(botMessage);
        print('Tin nhắn bot đã được lưu với ID: ${botDocRef.id}');

        setState(() {
          _messages.add(botMessage);
        });
      } catch (e) {
        print('Lỗi khi nhận phản hồi từ bot: $e');
        final errorMessage = {
          'sender': 'bot',
          'message': 'Xin lỗi, đã xảy ra lỗi khi tư vấn. Vui lòng thử lại sau.',
          'timestamp': DateTime.now().toIso8601String(),
          'userId': user.uid,
          'chatId': chatId,
        };

        await FirebaseFirestore.instance
            .collection('f0_consultations')
            .doc(chatId)
            .collection('messages')
            .add(errorMessage);

        setState(() {
          _messages.add(errorMessage);
        });
      }
    } catch (e) {
      print('Lỗi khi gửi tin nhắn: $e');
      setState(() {
        _messages.add({
          'sender': 'bot',
          'message': 'Xin lỗi, không thể gửi tin nhắn lúc này.',
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['sender'] == 'user';
    final timestampStr = message['timestamp'] ?? '';
    DateTime timestamp;

    try {
      timestamp = DateTime.parse(timestampStr);
    } catch (_) {
      timestamp = DateTime.now();
    }

    final timeFormatted = DateFormat('HH:mm dd/MM').format(timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message['message'] ?? '',
                style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Text(timeFormatted,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tư vấn sức khỏe F0')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessage(_messages[index]),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!_isLoading) _sendMessage();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Nhập triệu chứng hoặc câu hỏi...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                  color: Theme.of(context).primaryColor,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}