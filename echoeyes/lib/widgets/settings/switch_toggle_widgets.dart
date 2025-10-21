import 'package:echoeyes/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:echoeyes/models/settings_model.dart';

class SwitchSettingWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final AppSettings settings;
  final ValueChanged<bool> onChanged;

  const SwitchSettingWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.settings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.black,
            activeTrackColor: Colors.grey[200],
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[200],
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
