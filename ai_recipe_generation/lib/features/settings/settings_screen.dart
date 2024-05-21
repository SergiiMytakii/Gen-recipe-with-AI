import 'package:ai_recipe_generation/features/settings/settings_view_model.dart';
import 'package:ai_recipe_generation/features/settings/widget/llm_model_settings.dart';
import 'package:ai_recipe_generation/features/settings/widget/locale_settings.dart';
import 'package:ai_recipe_generation/theme.dart';
import 'package:ai_recipe_generation/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettigsScreen extends StatefulWidget {
  const SettigsScreen({
    super.key,
  });

  @override
  State<SettigsScreen> createState() => _SettigsScreenState();
}

class _SettigsScreenState extends State<SettigsScreen>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.only(
            left: MarketplaceTheme.spacing7,
            right: MarketplaceTheme.spacing7,
            bottom: MarketplaceTheme.spacing1,
            top: MarketplaceTheme.spacing7,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(MarketplaceTheme.defaultBorderRadius),
              topRight: Radius.circular(50),
              bottomRight:
                  Radius.circular(MarketplaceTheme.defaultBorderRadius),
              bottomLeft: Radius.circular(MarketplaceTheme.defaultBorderRadius),
            ),
            child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: MarketplaceTheme.borderColor),
                  borderRadius: const BorderRadius.only(
                    topLeft:
                        Radius.circular(MarketplaceTheme.defaultBorderRadius),
                    topRight: Radius.circular(50),
                    bottomRight:
                        Radius.circular(MarketplaceTheme.defaultBorderRadius),
                    bottomLeft:
                        Radius.circular(MarketplaceTheme.defaultBorderRadius),
                  ),
                  color: Colors.white,
                ),
                child: Column(
                  children: [LocaleSettings(), LLMModelSettings()],
                )),
          ),
        );
      },
    );
  }
}
