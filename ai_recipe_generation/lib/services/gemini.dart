import 'package:google_generative_ai/google_generative_ai.dart';

import '../features/prompt/prompt_model.dart';

class GeminiService {
  static Future<GenerateContentResponse> generateContentFromMultiModal(
      GenerativeModel model, PromptData prompt) async {
    final mainText = TextPart(prompt.imagePrompt);
    // final additionalTextParts =
    //     prompt.additionalTextInputs.map((t) => TextPart(t));
    final imagesParts = <DataPart>[];

    for (var f in prompt.images) {
      final bytes = await (f.readAsBytes());
      imagesParts.add(DataPart('image/jpeg', bytes));
    }

    final input = [
      Content.multi([...imagesParts, mainText])
    ];

    final result = await model.generateContent(
      input,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        topK: 32,
        topP: 1,
        maxOutputTokens: 4096,
      ),
    );

    return result;
  }

  static Future<GenerateContentResponse> generateContentFromText(
      GenerativeModel model, PromptData prompt) async {
    final additionalText =
        prompt.additionalTextInputs.map((t) => TextPart(t).toJson()).join("\n");

    print(prompt.mainPromptForGemini.substring(300));
    final input = [
      Content.text(
          '${prompt.mainPromptForGemini}\n  ${prompt.ingredients} \n $additionalText')
    ];
    final result = await model.generateContent(
      input,
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 32,
        topP: 1,
        maxOutputTokens: 4096,
      ),
    );
    return result;
  }
}
