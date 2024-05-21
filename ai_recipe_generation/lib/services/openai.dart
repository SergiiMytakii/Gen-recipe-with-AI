import 'dart:convert';

import 'package:ai_recipe_generation/constants.dart';
import 'package:ai_recipe_generation/features/prompt/prompt_model.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  static Future<String>? postOpenAIRequest(PromptData prompt) async {
    List<Map> jsonImages = [];

    for (var f in prompt.images) {
      final bytes = await f.readAsBytes();

      jsonImages.add({
        'type': 'image_url',
        'image_url': {"url": 'data:image/jpeg;base64,${base64Encode(bytes)}'}
      });
    }

    final body = json.encode({
      'model': 'gpt-4o',
      "response_format": {"type": "json_object"},
      'messages': [
        {'role': 'system', 'content': prompt.additionalTextInputs[0]},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt.mainPromptForChatGpt},
            ...jsonImages
          ]
        }
      ],
      'max_tokens': 4000
    });
    try {
      final res = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $openAIKey',
          },
          body: body);

      if (res.statusCode == 200) {
        var jsonData = json.decode(utf8.decode(res.body.codeUnits));
        final contentString =
            jsonData['choices']?.first['message']['content'] ?? '';

        return contentString as String;
      } else {
        throw Exception('OpenAI error: \n\n${res.body}');
      }
    } on Exception catch (e) {
      throw Exception('OpenAI error: \n\n$e');
    }
  }
}
