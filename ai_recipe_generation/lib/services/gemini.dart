import 'package:google_generative_ai/google_generative_ai.dart';

import '../features/prompt/prompt_model.dart';

class GeminiService {
  static Future<GenerateContentResponse> generateContent(
      GenerativeModel model, PromptData prompt) async {
    if (prompt.images.isEmpty) {
      return await GeminiService.generateContentFromText(model, prompt);
    } else {
      return await GeminiService.generateContentFromMultiModal(model, prompt);
    }
  }

  static Future<GenerateContentResponse> generateContentFromMultiModal(
      GenerativeModel model, PromptData prompt) async {
    final mainText = TextPart(prompt.textInput);
    final additionalTextParts =
        prompt.additionalTextInputs.map((t) => TextPart(t));
    final imagesParts = <DataPart>[];

    for (var f in prompt.images) {
      final bytes = await (f.readAsBytes());
      imagesParts.add(DataPart('image/jpeg', bytes));
    }
    additionalTextParts.forEach((t) => print(t.text + '\n'));
    final input = [
      Content.multi([...imagesParts, mainText, ...additionalTextParts])
    ];

    final result = await model.generateContent(
      input,
      generationConfig: GenerationConfig(
        temperature: 0.4,
        topK: 32,
        topP: 1,
        maxOutputTokens: 4096,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );

    return result;
  }

  static Future<GenerateContentResponse> generateContentFromText(
      GenerativeModel model, PromptData prompt) async {
    final mainText = TextPart(prompt.textInput);
    final additionalTextParts =
        prompt.additionalTextInputs.map((t) => TextPart(t).toJson()).join("\n");

    final result = await model.generateContent([
      Content.text(
        '${mainText.text} \n $additionalTextParts',
      )
    ]);
    return result;
  }
}
