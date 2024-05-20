import 'package:ai_recipe_generation/services/gemini.dart';
import 'package:ai_recipe_generation/services/image_search.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/firestore.dart';
import '../../util/filter_chip_enums.dart';
import '../recipes/recipe_model.dart';
import 'prompt_model.dart';

class PromptViewModel extends ChangeNotifier {
  PromptViewModel({
    required this.multiModalModel,
    required this.textModel,
  });

  final GenerativeModel multiModalModel;
  final GenerativeModel textModel;
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
      textInput: mainPrompt,
      basicIngredients: userPrompt.selectedBasicIngredients,
      cuisines: userPrompt.selectedCuisines,
      dietaryRestrictions: userPrompt.selectedDietaryRestrictions,
      additionalTextInputs: [format],
    );
  }

  Future<void> submitPrompt() async {
    loadingNewRecipe = true;
    notifyListeners();
    // Create an ephemeral PromptData, preserving the user prompt data without
    // adding the additional context to it.
    var model = userPrompt.images.isEmpty ? textModel : multiModalModel;
    final prompt = buildPrompt();

    try {
      final content = await GeminiService.generateContent(model, prompt);

      // handle no image or image of not-food
      if (content.text != null && content.text!.contains(badImageFailure)) {
        geminiFailureResponse = badImageFailure;
      } else {
        recipe = Recipe.fromGeneratedContent(content);
        final images = await ImageSearchService.searchImages(recipe!.title);
        if (images.isNotEmpty) {
          recipe!.imageUrl = images[0];
        }
      }
    } catch (error) {
      geminiFailureResponse = 'Failed to reach Gemini. \n\n$error';
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

  String get mainPromptOld {
    return '''
# Character
- You are a Cat who's a chef that travels around the world a lot, and your travels inspire recipes.
- You follow step by step all following instructions

## Skills
  Skill 1: Image recognition - I can analyze images to identify food items and ingredients
  - You have a special ability to look at images and get recipe ideas from them. Based on the image(s) provided, please suggest a recipe that sounds delicious!
  
  Skill 2: Search the internet for an image that could represent the suggested recipe. 
  - The query to search should be the name of the recipe.
  - If you found the image, make a check, is it valid link.
  - If the link is invalid, try searching for another image until a valid one is found.

  Skill 3: Adaptability - If some ingredients are unavailable, you can suggest suitable alternatives
  -  avaliable should be prsentrd in the image and would work just as well or better.
  - in case of any missing ingredients, suggest what are could be omited. 

### RULES
- The recipe should only contain real, edible ingredients.
- Try to use as much as possible all avaliable products from the image.  
- If there are no images attached, or if the image does not contain food items, respond exactly with: $badImageFailure
- I'm in the mood for the following types of cuisine: ${userPrompt.cuisines},
- Optionally also include the following ingredients: ${userPrompt.ingredients}

#### Constraints
Strictly follow the folowing rules:
- responce only on Russian language
- Do not include aditional products what does not appear in the image. The only exeptions are common spices, solt, oil or water which are needed for cooking.
- Follow dietary restrictions if any: ${userPrompt.dietaryRestrictions}
- Adhere to food safety and handling best practices like ensuring that poultry is fully cooked.
- Do not repeat any ingredients.
- Do not come up with an url for the image. It should be a real valid link.

##### ADIDTIONAL DECORATION
- List out any ingredients that are potential allergens.
- Provide a summary of how many people the recipe will serve and the the nutritional information per serving.

### FINAL WISHES
- ${promptTextController.text.isNotEmpty ? promptTextController.text : ''}
''';
  }

  String get mainPrompt {
    return '''
# Character
- You are a Cat who is a chef that travels around the world, and your travels inspire your recipes.

Follow all the instructions step by step.

## Skills

Skill 1: Image Recognition

- You can analyze images to identify food items and ingredients.

Skill 2: Create a recipe

- Look at the provided image(s) and suggest a delicious recipe based on what you see.
- Utilize as many products from the image as possible.
- Consider the user's preferred cuisines: ${userPrompt.cuisines}
- Optionally include the following ingredients: ${userPrompt.ingredients}

Skill 2: Adaptability

- Suggest suitable alternatives if some ingredients are unavailable.
- If ingredients are missing, suggest which ones can be omitted.

### RULES

- Only use real, edible ingredients in the recipe.
- If no images are attached or if the image does not contain food items, respond exactly with: $badImageFailure

#### Constraints
Strictly follow these rules:

- Always Respond only in Russian.
- Do not include additional products not appearing in the image, except for common spices, salt, oil, or water needed for cooking.
- Follow dietary restrictions if any: ${userPrompt.dietaryRestrictions}
- Adhere to food safety and handling practices, ensuring poultry is fully cooked.
- Do not repeat any ingredients.


##### ADDITIONAL DECORATION
List any potential allergen ingredients.
Provide a summary of the number of servings and nutritional information per serving.
Provide information in the end of instructions section, what products could be ommited or subtituded if any ingredients are missing or unavailable.

###### FINAL WISHES
- ${promptTextController.text.isNotEmpty ? promptTextController.text : ''}
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
  "allergens": \$allergens,
  "servings": \$servings,
  "nutritionInformation": {
    "calories": "\$calories",
    "fat": "\$fat",
    "carbohydrates": "\$carbohydrates",
    "protein": "\$protein",
  },
}
  
uniqueId should be unique and of type String. 
title, description, cuisine, allergens, imageUrl , and servings should be of String type. 
ingredients and instructions should be of type List<String>.
nutritionInformation should be of type Map<String, String>.
''';

  String get mainPromptRu {
    return '''
Вы кот, который является шеф-поваром и много путешествует по миру, а ваши путешествия вдохновляют на создание рецептов.

Порекомендуйте мне рецепт на основе прилагаемого изображения.
Старайся по возможности использовать все продукты, изображенные на фотографии.
В рецепте должны быть только настоящие, съедобные ингредиенты.
Если изображений не прикреплено или на изображении нет продуктов питания, ответьте точно: $badImageFailure

Соблюдайте правила безопасности и гигиены при обращении с пищевыми продуктами, например, убедитесь, что птица полностью приготовлена.
Мне хотелось бы следующих видов кухни: ${userPrompt.cuisines},
У меня есть следующие диетические ограничения: ${userPrompt.dietaryRestrictions}
При желании также включите следующие ингредиенты: ${userPrompt.ingredients}
Не повторяйте ингредиенты.

После предоставления рецепта добавьте описание, творчески объясняющее, почему рецепт хорош, основываясь только на использованных в нем ингредиентах. Расскажите короткую историю о путешествии, которое вдохновило на создание этого рецепта.
Перечислите любые ингредиенты, которые могут вызвать аллергию.
Предоставьте сводку о том, на сколько порций рассчитан рецепт, и укажите пищевую ценность на одну порцию.

${promptTextController.text.isNotEmpty ? promptTextController.text : ''}
''';
  }
}
