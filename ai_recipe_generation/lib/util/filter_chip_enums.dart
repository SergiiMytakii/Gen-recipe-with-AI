import 'package:easy_localization/easy_localization.dart';

enum CuisineFilter {
  italian,
  mexican,
  american,
  french,
  japanese,
  chinese,
  indian,
  greek,
  moroccan,
  ethiopian,
  southAfrican,
}

enum BasicIngredientsFilter {
  oil,
  butter,
  flour,
  bread,
  ketchup,
  sugar,
  milk,
  vinegar,
}

String basicIngredientsFilterReadable(BasicIngredientsFilter filter) {
  return switch (filter) {
    BasicIngredientsFilter.oil => 'oil'.tr(),
    BasicIngredientsFilter.butter => 'butter'.tr(),
    BasicIngredientsFilter.flour => 'flour'.tr(),
    BasicIngredientsFilter.bread => 'bread'.tr(),
    BasicIngredientsFilter.ketchup => 'ketchup'.tr(),
    BasicIngredientsFilter.sugar => 'sugar'.tr(),
    BasicIngredientsFilter.milk => 'milk'.tr(),
    BasicIngredientsFilter.vinegar => 'vinegar'.tr(),
  };
}

enum DietaryRestrictionsFilter {
  vegan,
  vegetarian,
  lactoseIntolerant,
  kosher,
  keto,
  wheatAllergies,
  nutAllergies,
  fishAllergies,
  soyAllergies,
}

String dietaryRestrictionReadable(DietaryRestrictionsFilter filter) {
  return switch (filter) {
    DietaryRestrictionsFilter.vegan => 'vegan'.tr(),
    DietaryRestrictionsFilter.vegetarian => 'vegetarian'.tr(),
    DietaryRestrictionsFilter.lactoseIntolerant => 'dairy free'.tr(),
    DietaryRestrictionsFilter.kosher => 'kosher'.tr(),
    DietaryRestrictionsFilter.keto => 'low carb'.tr(),
    DietaryRestrictionsFilter.wheatAllergies => 'wheat allergy'.tr(),
    DietaryRestrictionsFilter.nutAllergies => 'nut allergy'.tr(),
    DietaryRestrictionsFilter.fishAllergies => 'fish allergy'.tr(),
    DietaryRestrictionsFilter.soyAllergies => 'soy allergy'.tr(),
  };
}

String cuisineReadable(CuisineFilter filter) {
  return switch (filter) {
    CuisineFilter.italian => 'Italian'.tr(),
    CuisineFilter.mexican => 'Mexican'.tr(),
    CuisineFilter.american => 'American'.tr(),
    CuisineFilter.french => 'French'.tr(),
    CuisineFilter.japanese => 'Japanese'.tr(),
    CuisineFilter.chinese => 'Chinese'.tr(),
    CuisineFilter.indian => 'Indian'.tr(),
    CuisineFilter.ethiopian => 'Ethiopian'.tr(),
    CuisineFilter.moroccan => 'Moroccan'.tr(),
    CuisineFilter.greek => 'Greek'.tr(),
    CuisineFilter.southAfrican => 'South African'.tr(),
  };
}
