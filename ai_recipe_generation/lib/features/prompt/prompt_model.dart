import 'package:image_picker/image_picker.dart';

import '../../util/filter_chip_enums.dart';

class PromptData {
  PromptData({
    required this.images,
    required this.mainPromptForGemini,
    required this.mainPromptForChatGpt,
    required this.imagePrompt,
    required this.locale,
    this.ingredients,
    Set<BasicIngredientsFilter>? basicIngredients,
    Set<CuisineFilter>? cuisines,
    Set<DietaryRestrictionsFilter>? dietaryRestrictions,
    List<String>? additionalTextInputs,
  })  : additionalTextInputs = additionalTextInputs ?? [],
        selectedBasicIngredients = basicIngredients ?? {},
        selectedCuisines = cuisines ?? {},
        selectedDietaryRestrictions = dietaryRestrictions ?? {};

  List<XFile> images;
  String mainPromptForGemini;
  String mainPromptForChatGpt;
  String imagePrompt;
  String locale;
  String? ingredients;
  List<String> additionalTextInputs;
  Set<BasicIngredientsFilter> selectedBasicIngredients;
  Set<CuisineFilter> selectedCuisines;
  Set<DietaryRestrictionsFilter> selectedDietaryRestrictions;

  PromptData.empty()
      : images = [],
        additionalTextInputs = [],
        locale = 'ru',
        selectedBasicIngredients = {},
        selectedCuisines = {},
        selectedDietaryRestrictions = {},
        mainPromptForChatGpt = '',
        mainPromptForGemini = '',
        imagePrompt = '';

  String get cuisines {
    return selectedCuisines.map((catFilter) => catFilter.name).join(",");
  }

  String get basicIngredients {
    return selectedBasicIngredients
        .map((ingredient) => ingredient.name)
        .join(", ");
  }

  String get dietaryRestrictions {
    return selectedDietaryRestrictions
        .map((restriction) => restriction.name)
        .join(", ");
  }

  PromptData copyWith({
    List<XFile>? images,
    String? mainPromptForGemini,
    String? mainPromptForChatGpt,
    String? imagePrompt,
    String? ingredients,
    List<String>? additionalTextInputs,
    Set<BasicIngredientsFilter>? basicIngredients,
    Set<CuisineFilter>? cuisineSelections,
    Set<DietaryRestrictionsFilter>? dietaryRestrictions,
  }) {
    return PromptData(
      images: images ?? this.images,
      mainPromptForGemini: mainPromptForGemini ?? this.mainPromptForGemini,
      mainPromptForChatGpt: mainPromptForChatGpt ?? this.mainPromptForChatGpt,
      imagePrompt: imagePrompt ?? this.imagePrompt,
      ingredients: ingredients,
      locale: locale,
      additionalTextInputs: additionalTextInputs ?? this.additionalTextInputs,
      basicIngredients: basicIngredients ?? selectedBasicIngredients,
      cuisines: cuisineSelections ?? selectedCuisines,
      dietaryRestrictions: dietaryRestrictions ?? selectedDietaryRestrictions,
    );
  }
}
