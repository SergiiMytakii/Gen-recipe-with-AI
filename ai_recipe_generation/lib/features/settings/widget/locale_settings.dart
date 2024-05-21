import 'dart:async';

import 'package:ai_recipe_generation/features/settings/settings_view_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LocaleSettings extends StatelessWidget {
  LocaleSettings({super.key});

  final List<String> _locales = ['en', 'ru', 'uk'];

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.tr('Change Locale'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          DropdownButton<String>(
            value: viewModel.currentLocale,
            onChanged: (newValue) async {
              await context.setLocale(Locale(newValue!));
              unawaited(viewModel.saveLocale(newValue));
            },
            items: _locales.map<DropdownMenuItem<String>>((value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
