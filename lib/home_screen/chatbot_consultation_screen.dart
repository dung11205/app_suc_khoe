import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class ChatbotConsultationScreen extends StatefulWidget {
  final String name;
  final String symptom;

  const ChatbotConsultationScreen({
    super.key,
    required this.name,
    required this.symptom,
  });

  @override
  State<ChatbotConsultationScreen> createState() => _ChatbotConsultationScreenState();
}

class _ChatbotConsultationScreenState extends State<ChatbotConsultationScreen> {
  final List<Map<String, String>> _messages = [];
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const String _apiKey = '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';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  String? _lastChatbotResponse;
  bool _isLoading = false;
  final List<Map<String, String>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Thêm tin nhắn chào và triệu chứng người dùng vào giao diện
    _messages.add({
      'sender': 'Chatbot',
      'message': 'Xin chào ${widget.name}! Bạn đang gặp triệu chứng: "${widget.symptom}". Tôi sẽ tư vấn ngay!',
    });

    // Khởi tạo lịch sử chat với vai trò hệ thống
    _chatHistory.add({
      'role': 'system',
      'content': 'Bạn là một chatbot tư vấn y tế, giúp bệnh nhân hiểu về các triệu chứng và đưa ra lời khuyên sơ bộ. '
          'Luôn khuyến khích bệnh nhân đến gặp bác sĩ nếu triệu chứng nghiêm trọng. '
          'Trả lời bằng tiếng Việt, ngắn gọn, dễ hiểu và chuyên nghiệp.',
    });

    // Thêm triệu chứng vào lịch sử chat
    _chatHistory.add({
      'role': 'user',
      'content': 'Tôi đang gặp triệu chứng: ${widget.symptom}. Hãy tư vấn cho tôi.',
    });

    // Gọi API ngay sau khi giao diện được vẽ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendToOpenRouter(widget.symptom);
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendToOpenRouter(String message, {bool isInitialMessage = true}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-4-scout:free',
          'messages': _chatHistory,
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final aiResponse = data['choices'][0]['message']['content'];

        _chatHistory.add({
          'role': 'assistant',
          'content': aiResponse,
        });

        setState(() {
          _messages.add({
            'sender': 'Chatbot',
            'message': aiResponse,
          });
          _lastChatbotResponse = aiResponse;
          _isLoading = false;
        });

        _scrollToBottom();

        if (isInitialMessage) {
          await _saveToFirestore(widget.name, widget.symptom, aiResponse);
        }
      } else {
        setState(() {
          _messages.add({
            'sender': 'Chatbot',
            'message': 'Xin lỗi, có lỗi khi kết nối với AI. Vui lòng thử lại sau.',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'Chatbot',
          'message': 'Lỗi: $e. Vui lòng kiểm tra kết nối hoặc thử lại.',
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveToFirestore(String name, String symptom, String chatbotResponse) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để lưu yêu cầu')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('remote_consulting_requests').add({
        'userId': user.uid,
        'name': name,
        'symptom': symptom,
        'timestamp': Timestamp.now(),
        'status': 'responded',
        'doctorResponse': chatbotResponse,
        'isChatbot': true,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu yêu cầu: $e')),
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;

    setState(() {
      _messages.add({
        'sender': 'Bạn',
        'message': userMessage,
      });
    });

    _chatHistory.add({
      'role': 'user',
      'content': userMessage,
    });

    _messageController.clear();
    _scrollToBottom();

    _sendToOpenRouter(userMessage, isInitialMessage: false);
  }

  Widget _buildChatBubble(String sender, String message, bool isBot) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isBot ? Colors.blue[100] : Colors.green[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14.0,
                color: Colors.black,
              ),
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
        title: const Text(
          'Tư vấn với Chatbot',
          style: TextStyle(fontFamily: 'Roboto'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hướng dẫn sử dụng'),
                  content: const Text(
                    'Bạn có thể hỏi thêm về triệu chứng hoặc các vấn đề sức khỏe khác. '
                    'Chatbot sẽ cung cấp tư vấn sơ bộ, nhưng hãy đến gặp bác sĩ nếu cần kiểm tra chuyên sâu.',
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Đã hiểu'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isBot = message['sender'] == 'Chatbot';
                return _buildChatBubble(
                  message['sender']!,
                  message['message']!,
                  isBot,
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Đang trả lời...',
                    style: TextStyle(fontStyle: FontStyle.italic, fontFamily: 'Roboto'),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập câu hỏi hoặc triệu chứng thêm...',
                      hintStyle: const TextStyle(fontFamily: 'Roboto'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    style: const TextStyle(fontFamily: 'Roboto'),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}