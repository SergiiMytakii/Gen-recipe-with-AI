import 'package:ai_recipe_generation/services/gemini.dart';
import 'package:ai_recipe_generation/services/image_search.dart';
import 'package:ai_recipe_generation/services/openai.dart';
import 'package:ai_recipe_generation/util/llm_models_enum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:langchain_openai/langchain_openai.dart';
import '../../services/firestore.dart';
import '../../util/filter_chip_enums.dart';
import '../recipes/recipe_model.dart';
import 'prompt_model.dart';

class PromptViewModel extends ChangeNotifier {
  PromptViewModel({
    required this.vertexAiModel,
    required this.openAiModel,
  });

  final GenerativeModel vertexAiModel;
  final ChatOpenAI openAiModel;
  bool loadingNewRecipe = false;

  PromptData userPrompt = PromptData.empty();
  TextEditingController promptTextController = TextEditingController();

  String badImageFailure =
      "The recipe request either does not contain images, or does not contain images of food items. I cannot recommend a recipe."
          .tr();

  Recipe? recipe;
  String? _geminiFailureResponse;
  String? get geminiFailureResponse => _geminiFailureResponse;
  set geminiFailureResponse(String? value) {
    _geminiFailureResponse = value;
    notifyListeners();
  }

  void notify() => notifyListeners();

  void addImage(XFile image) {
    userPrompt.images.insert(0, image);
    notifyListeners();
  }

  void addAdditionalPromptContext(String text) {
    final existingInputs = userPrompt.additionalTextInputs;
    userPrompt.copyWith(additionalTextInputs: [...existingInputs, text]);
  }

  void removeImage(XFile image) {
    userPrompt.images.removeWhere((el) => el.path == image.path);
    notifyListeners();
  }

  void resetPrompt() {
    userPrompt = PromptData.empty();
    notifyListeners();
  }

  // Creates an ephemeral prompt with additional text that the user shouldn't be
  // concerned with to send to Gemini, such as formatting.
  PromptData buildPrompt() {
    return PromptData(
      images: userPrompt.images,
      mainPromptForGemini: mainPromptGemini,
      mainPromptForChatGpt: mainPromptChatGpt,
      imagePrompt: visionPrompt,
      locale: userPrompt.locale,
      basicIngredients: userPrompt.selectedBasicIngredients,
      cuisines: userPrompt.selectedCuisines,
      dietaryRestrictions: userPrompt.selectedDietaryRestrictions,
      additionalTextInputs: [format],
    );
  }

  Future<void> submitPrompt(LlmModels model) async {
    switch (model) {
      case LlmModels.Gemini:
        await generateWithGemini();

      case LlmModels.ChatGpt4o:
        await generateWithOpenAI();
    }
  }

  Future<void> generateWithGemini() async {
    loadingNewRecipe = true;
    notifyListeners();

    final prompt = buildPrompt();

    try {
      final ingredients = await GeminiService.generateContentFromMultiModal(
          vertexAiModel, prompt);
      if (ingredients.text != null &&
          ingredients.text!.contains(badImageFailure)) {
        geminiFailureResponse = badImageFailure;
      } else {
        prompt.ingredients = 'Available ingredients:  ${ingredients.text}';
        final content =
            await GeminiService.generateContentFromText(vertexAiModel, prompt);

        // handle no image or image of not-food
        if (content.text != null &&
            (content.text!.contains("Я не могу") ||
                content.text!.contains("Я не можу") ||
                content.text!.contains("I cannot") ||
                content.text!.contains("I can't"))) {
          geminiFailureResponse = content.text;
        } else {
          recipe = Recipe.fromGeneratedContent(content);
          if (recipe != null) {
            recipe!.imageUrl =
                await ImageSearchService.searchImage(recipe!.title) ?? '';
          }
        }
      }
    } catch (error) {
      geminiFailureResponse = 'Gemini error: \n\n$error';
      if (kDebugMode) {
        print(error);
      }
      loadingNewRecipe = false;
    }

    loadingNewRecipe = false;
    resetPrompt();
    notifyListeners();
  }

  Future<void> generateWithOpenAI() async {
    loadingNewRecipe = true;
    notifyListeners();

    final prompt = buildPrompt();

    try {
      final String? response = await OpenAIService.postOpenAIRequest(prompt);
      if (response != null) {
        recipe = Recipe.fromOpenAiContent(response);
        if (recipe != null) {
          recipe!.imageUrl =
              await ImageSearchService.searchImage(recipe!.title) ?? '';
        }
      } else {
        geminiFailureResponse = 'OpenAI error';
      }
    } catch (error) {
      geminiFailureResponse = 'Gemini error: \n\n$error';
      if (kDebugMode) {
        print(error);
      }
      loadingNewRecipe = false;
    }

    loadingNewRecipe = false;
    resetPrompt();
    notifyListeners();
  }

  void saveRecipe() {
    FirestoreService.saveRecipe(recipe!);
  }

  void addBasicIngredients(Set<BasicIngredientsFilter> ingredients) {
    userPrompt.selectedBasicIngredients.addAll(ingredients);
    notifyListeners();
  }

  void addCategoryFilters(Set<CuisineFilter> categories) {
    userPrompt.selectedCuisines.addAll(categories);
    notifyListeners();
  }

  void addDietaryRestrictionFilter(
      Set<DietaryRestrictionsFilter> restrictions) {
    userPrompt.selectedDietaryRestrictions.addAll(restrictions);
    notifyListeners();
  }

  String get visionPrompt {
    return '''
Your task is to analyze the image and return a list of edible products you see, along with their approximate quantities. 
If no images are attached or the image does not contain any edible products, respond exactly with: $badImageFailure without tranlsations to another language.

Please format your response as follows:
"Product1: Quantity1, Product2: Quantity2, ..."

For example:
"Potatoes: 1 kg, Tomatoes: 2, Onions: 0.5 kg"

If you cannot determine the quantity, provide your best estimate (e.g. "Bananas: a bunch"). Be concise and avoid unnecessary words or descriptions beyond the requested product list.
''';
  }

  String get mainPromptGemini {
    return '''
# Character
- You are a friendly and creative Cat who is a chef that travels around the world, and your travels inspire your recipes.
Follow all the instructions step by step:

Step 1: Create a recipe
  - Look at the provided in the end list of ingredients and suggest a delicious recipe based on on what's available.
  - Utilize as many ingredients as possible from the list and ptionally include the following ingredients: ${userPrompt.basicIngredients}
  - Consider the user's preferred cuisines: ${userPrompt.cuisines}
  - Follow dietary restrictions if any: ${userPrompt.dietaryRestrictions}
  - ${promptTextController.text.isNotEmpty ? 'Consider the following wishes: ${promptTextController.text}' : ''}

Step 2: Adapt recipe to avaliable ingredients
  - Suggest suitable alternatives if some ingredients are unavailable.
  - If some ingredients are missing in the list, suggest which ones can be omitted.
  - Do not include additional products what you do not have, except for common spices, salt, oil, or water needed for cooking.

Step 3: Provide a summary of the number of servings and nutritional information per serving.

# Constraints
Strictly follow these rules:
  - Only use real, edible ingredients in the recipe.
  - Always Respond only in ${userPrompt.locale} language.
  - Adhere to food safety and handling practices, ensuring poultry is fully cooked.
  - Consider the compatibility of ingredients. For example, strawberries do not pair well with meat in the same dish, and milk with cucumbers, etc.
  - Do not repeat any ingredients.
''';
  }

  final String format = '''
Return the recipe as valid JSON using the following structure:
{
  "id": \$uniqueId,
  "title": \$recipeTitle,
  "ingredients": \$ingredients,
  "description": \$description,
  "instructions": \$instructions,
  "cuisine": \$cuisineType,
  "servings": \$servings,
  "nutritionInformation": {
    "calories": "\$calories",
    "fat": "\$fat",
    "carbohydrates": "\$carbohydrates",
    "protein": "\$protein",
  },
}
  
uniqueId should be unique and of type String. 
title, description, cuisine, imageUrl , and servings should be of String type. 
ingredients and instructions should be of type List<String>.
nutritionInformation should be of type Map<String, String>.
''';

  String get mainPromptChatGpt {
    return '''
# Character
- You are a Cat who is a chef that travels around the world, and your travels inspire your recipes.

Follow all the instructions step by step.


Step 1: Image Recognition

- Analyze image(s) to identify food items and ingredients. Take only eadible ingredients into account.
- If no images are attached or if the image does not contain food items, respond exactly with: $badImageFailure without tranlsations to another language.

Step 2: Create a recipe

- suggest a delicious recipe based on what ingridients are available and include the following ingredients: ${userPrompt.ingredients}
- Utilize as many products from the image as possible.
- Consider the user's preferred cuisines: ${userPrompt.cuisines}
- Only use real, edible ingredients in the recipe.
- Do not include additional products not appearing in the image, except for common spices, salt, oil, or water needed for cooking.
- ${promptTextController.text.isNotEmpty ? 'Consider the following wishes: ${promptTextController.text}' : ''}
- Follow dietary restrictions if any: ${userPrompt.dietaryRestrictions}

Step 3: Adapt pecipe

- Suggest suitable alternatives if some ingredients are unavailable.
- If ingredients are missing, suggest which ones can be omitted.

Step 4: Provide a summary of the number of servings and nutritional information per serving.


#### Constraints
Strictly follow these rules:

- Always Respond only in ${userPrompt.locale} language.
- Adhere to food safety and handling practices, ensuring poultry is fully cooked.
- Do not repeat any ingredients.

''';
  }
}
