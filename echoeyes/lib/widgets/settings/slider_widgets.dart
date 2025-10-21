import 'package:echoeyes/widgets/custom_text.dart';
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
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.black,
                    inactiveTrackColor: Colors.grey[200],
                    thumbColor: Colors.black,
                    overlayColor: Colors.black.withValues(alpha: 0.2),
                  ),
                  child: Slider(value: value, onChanged: onChanged),
                ),
              ),
              Text(
                _getDisplayValue(),
                style: MyTextStyles.medium.copyWith(
                  color: Colors.black,
                  fontSize: settings.fontSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDisplayValue() {
    if (title == 'Font Size') return '${(12 + (value * 24)).toInt()}px';
    if (title.contains('Confidence')) return value.toStringAsFixed(2);
    return '${(value * 100).toInt()}%';
  }
}
