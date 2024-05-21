import 'package:ai_recipe_generation/features/settings/settings_view_model.dart';
import 'package:ai_recipe_generation/util/llm_models_enum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LLMModelSettings extends StatelessWidget {
  final List<LlmModels> _models = LlmModels.values;

  LLMModelSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.tr('Change LLM Model'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          DropdownButton<String>(
            value: viewModel.currentLlmModel.name,
            onChanged: (newValue) {
              viewModel.saveModel(newValue!);
            },
            items: _models.map<DropdownMenuItem<String>>((value) {
              return DropdownMenuItem<String>(
                value: value.name,
                child: Text(value.name),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
