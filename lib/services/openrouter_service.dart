import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';

class OpenRouterService {
  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  Future<String> askAssistant({
    required String prompt,
    List<Map<String, String>> history = const [],
  }) async {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            'You are TrackDIU SmartBus assistant. Keep answers short, clear, and focused on DIU bus routes, schedules, and transport support.'
      },
      ...history,
      {'role': 'user', 'content': prompt},
    ];

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer ${AppConstants.openRouterApiKey}',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://trackdiu.demo.app',
        'X-Title': 'TrackDIU SmartBus Demo',
      },
      body: jsonEncode({
        'model': AppConstants.openRouterModel,
        'messages': messages,
        'temperature': 0.3,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('OpenRouter request failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('OpenRouter returned no choices');
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw Exception('OpenRouter returned empty content');
    }
    return content.trim();
  }
}
