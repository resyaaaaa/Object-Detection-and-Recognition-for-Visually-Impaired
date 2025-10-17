import 'package:flutter/material.dart';
import 'package:echoeyes/models/settings_model.dart';

class SliderSettingWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final AppSettings settings;
  final ValueChanged<double> onChanged;

  const SliderSettingWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.settings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: settings.switchMode ? const Color(0xFFFFD900) : Colors.white,
      elevation: settings.switchMode ? 0 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            Text(
              subtitle,
              style: TextStyle(
                fontSize: settings.fontSize - 2,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.black,
                      inactiveTrackColor: Colors.grey[400],
                      thumbColor: Colors.black,
                      overlayColor: Colors.black.withValues(alpha: 0.2),
                    ),
                    child: Slider(value: value, onChanged: onChanged),
                  ),
                ),
                Text(
                  _getDisplayValue(),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: settings.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayValue() {
    if (title == 'Font Size') {
      return '${(12 + (value * 24)).toInt()}px';
    } else if (title == 'Confidence Threshold'){
      return value.toStringAsFixed(2);
    }
    return '${(value * 100).toInt()}%';
  }
}
