import 'package:echoeyes/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:echoeyes/models/settings_model.dart';

class DropdownSettingWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final AppSettings settings;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  const DropdownSettingWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.settings,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey[200]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: MyTextStyles.semiBold.copyWith(
              fontSize: settings.fontSize + 2,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: MyTextStyles.medium.copyWith(
              fontSize: settings.fontSize - 2,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Colors.black),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            dropdownColor: Colors.white,
            style: MyTextStyles.semiBold.copyWith(
              fontSize: settings.fontSize,
              color: Colors.black,
            ),
            items: options.entries
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
