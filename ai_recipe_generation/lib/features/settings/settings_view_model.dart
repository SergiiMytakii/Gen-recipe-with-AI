import 'package:ai_recipe_generation/util/llm_models_enum.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  String currentLocale = 'ru';
  LlmModels currentLlmModel = LlmModels.Gemini;

  SettingsViewModel() {
    loadLocale();
    loadModel();
  }

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();

    currentLocale = prefs.getString('locale') ?? 'ru';
    notifyListeners();
  }

  Future<void> saveLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
    currentLocale = locale;
    notifyListeners();
  }

  Future<void> loadModel() async {
    final prefs = await SharedPreferences.getInstance();
    String modelName = prefs.getString('llmModel') ?? LlmModels.Gemini.name;
    currentLlmModel = LlmModels.values.byName(modelName);
    notifyListeners();
  }

  Future<void> saveModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('llmModel', model);
    currentLlmModel = LlmModels.values.byName(model);
    notifyListeners();
  }
}
