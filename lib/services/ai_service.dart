import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = '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';
  static const String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  static Future<String> getGPTReply(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "mistralai/mistral-medium",
          "messages": [
            {
              "role": "system",
              "content": "Bạn là bác sĩ chuyên tư vấn sức khỏe F0. Trả lời ngắn gọn, rõ ràng và dễ hiểu."
            },
            {"role": "user", "content": message},
          ],
          "temperature": 0.7,
          "max_tokens": 500 
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].trim();
      } else {
        print('❌ OpenRouter error: ${response.statusCode} - ${response.body}');
        return 'Xin lỗi, hiện tại tôi không thể trả lời. Vui lòng thử lại sau.';
      }
    } catch (e) {
      print('❌ Exception when calling AI: $e');
      return 'Đã xảy ra lỗi kết nối. Vui lòng thử lại sau.';
    }
  }
}
