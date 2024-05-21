import 'package:ai_recipe_generation/constants.dart';
import 'package:ai_recipe_generation/features/settings/settings_view_model.dart';
import 'package:ai_recipe_generation/util/device_info.dart';
import 'package:ai_recipe_generation/util/tap_recorder.dart';
import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:provider/provider.dart';

import 'features/prompt/prompt_view_model.dart';
import 'features/recipes/recipes_view_model.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'theme.dart';

late CameraDescription camera;
late BaseDeviceInfo deviceInfo;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  deviceInfo = await DeviceInfo.initialize(DeviceInfoPlugin());
  if (DeviceInfo.isPhysicalDeviceWithCamera(deviceInfo)) {
    final cameras = await availableCameras();
    camera = cameras.first;
  }
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      useOnlyLangCode: true,
      supportedLocales: const [Locale('en'), Locale('uk'), Locale('ru')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ru'),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late GenerativeModel geminiVisionProModel;
  late ChatOpenAI openAiModel;
  @override
  void initState() {
    const apiKey = api_key;
    if (apiKey == 'key not found') {
      throw InvalidApiKey(
        'Key not found in environment. Please add an API key.',
      );
    }

    geminiVisionProModel = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        topK: 32,
        topP: 1,
        maxOutputTokens: 4096,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );

    openAiModel = ChatOpenAI(
        apiKey: openAIKey,
        defaultOptions:
            const ChatOpenAIOptions(temperature: 0.9, model: 'gpt-4o'));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final recipesViewModel = SavedRecipesViewModel();
    final settingsViewModel = SettingsViewModel();

    return TapRecorder(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => PromptViewModel(
              vertexAiModel: geminiVisionProModel,
              openAiModel: openAiModel,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => recipesViewModel,
          ),
          ChangeNotifierProvider(
            create: (_) => settingsViewModel,
          ),
        ],
        child: SafeArea(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MarketplaceTheme.theme,
            // supportedLocales: const [
            //   Locale('en', ''), // English
            //   Locale('ru', ''), // Russian
            //   Locale('uk', ''), // Ukrainian
            // ],
            // localizationsDelegates: const [
            //   GlobalMaterialLocalizations.delegate,
            //   GlobalWidgetsLocalizations.delegate,
            //   GlobalCupertinoLocalizations.delegate,
            // ],
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            // locale: const Locale('ru', 'RU'),
            locale: context.locale,
            scrollBehavior: const ScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.mouse,
                PointerDeviceKind.touch,
                PointerDeviceKind.stylus,
                PointerDeviceKind.unknown,
              },
            ),
            home: const AdaptiveRouter(),
          ),
        ),
      ),
    );
  }
}
