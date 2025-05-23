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
    if (user == null) {
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
        'chatId': chatRef.id,
      };

      await FirebaseFirestore.instance
          .collection('f0_consultations')
          .doc(chatRef.id)
          .collection('messages')
          .add(defaultBotMessage);

      setState(() {
        _messages.clear();
        _messages.add(defaultBotMessage);
      });
    } catch (e) {
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
    if (user == null) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'message': 'Vui lòng đăng nhập để tiếp tục.',
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
      return;
    }

    String? chatId;
    if (_messages.isNotEmpty) {
      chatId = _messages.first['chatId'] as String?;
    }
    if (chatId == null) {
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
      await FirebaseFirestore.instance
          .collection('f0_consultations')
          .doc(chatId)
          .collection('messages')
          .add(userMessage);

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

        await FirebaseFirestore.instance
            .collection('f0_consultations')
            .doc(chatId)
            .collection('messages')
            .add(botMessage);

        setState(() {
          _messages.add(botMessage);
        });
      } catch (e) {
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
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isUser ? Colors.lightBlue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['message'] ?? '',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              timeFormatted,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tư vấn sức khỏe F0'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đang phản hồi...',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!_isLoading) _sendMessage();
                      },
                      decoration: InputDecoration(
                        hintText: 'Nhập triệu chứng hoặc câu hỏi...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
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
          )
        ],
      ),
    );
  }
}