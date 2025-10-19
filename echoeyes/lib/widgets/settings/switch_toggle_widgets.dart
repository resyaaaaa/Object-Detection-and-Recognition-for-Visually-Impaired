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
    final isHighContrast = settings.switchMode;

    return Card(
      color: isHighContrast ? const Color(0xFFFFD900) : Colors.white,
      elevation: isHighContrast ? 0 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: settings.fontSize + 2,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: settings.fontSize - 2,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.black,
              activeTrackColor: Colors.grey[400],
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
