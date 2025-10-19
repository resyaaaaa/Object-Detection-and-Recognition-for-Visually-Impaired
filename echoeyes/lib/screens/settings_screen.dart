import 'package:flutter/material.dart';
import 'package:echoeyes/models/settings_model.dart';
import 'package:echoeyes/services/settings_service.dart';
import 'package:echoeyes/services/tts_service.dart';
import 'package:echoeyes/widgets/custom_text.dart';
import 'package:echoeyes/widgets/settings/dropdown_widgets.dart';
import 'package:echoeyes/widgets/settings/slider_widgets.dart';
import 'package:echoeyes/widgets/settings/switch_toggle_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  bool _isLoading = true;
  bool _hasChanges = false;
  bool _isSaving = false;

  static const Map<String, String> _languageOptions = {
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
    'fr-FR': 'French',
    'de-DE': 'German',
    'hi-IN': 'Hindi (India)',
    'id-ID': 'Indonesian',
    'ms-MY': 'Malay',
    'zh-CN': 'Mandarin (Simplified)',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final loaded = await SettingsService.loadSettings();
      setState(() {
        _settings = loaded;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _settings = widget.settings;
        _isLoading = false;
      });
      _showErrorDialog('Failed to load settings: ${e.toString()}');
    }
  }

  void _markAsChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  void _updateSetting(AppSettings Function(AppSettings) updater) {
    setState(() => _settings = updater(_settings));
    _markAsChanged();
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await SettingsService.saveSettings(_settings);
      await TTSService.updateSettings(_settings);
      if (mounted) {
        setState(() {
          _hasChanges = false;
          _isSaving = false;
        });
        Navigator.pop(context, _settings);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorDialog('Failed to save settings: ${e.toString()}');
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            _settings.switchMode ? const Color(0xFFFFD900) : Colors.white,
        title: Text('Error',
            style: MyTextStyles.bold.copyWith(
                fontSize: _settings.fontSize + 2, color: Colors.black)),
        content: Text(error,
            style: MyTextStyles.medium
                .copyWith(fontSize: _settings.fontSize, color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: MyTextStyles.bold
                    .copyWith(fontSize: _settings.fontSize, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<bool> _showUnsavedChangesDialog() async {
    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            _settings.switchMode ? const Color(0xFFFFD900) : Colors.white,
        title: Text('Unsaved Changes',
            style: MyTextStyles.bold.copyWith(
                fontSize: _settings.fontSize + 2, color: Colors.black)),
        content: Text('Do you want to save your changes before leaving?',
            style: MyTextStyles.medium
                .copyWith(fontSize: _settings.fontSize, color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Discard',
                style: MyTextStyles.bold
                    .copyWith(fontSize: _settings.fontSize, color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Save',
                style: MyTextStyles.bold
                    .copyWith(fontSize: _settings.fontSize, color: Colors.black)),
          ),
        ],
      ),
    );
    if (save == true) {
      await _saveSettings();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            widget.settings.switchMode ? const Color(0xFFFFD900) : Colors.white,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.black),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          if (shouldPop && mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor:
            _settings.switchMode ? const Color(0xFFFFD900) : Colors.white,
        appBar: _buildAppBar(),
        body: ScrollConfiguration(
          behavior: const _NoGlow(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Audio Settings', _buildAudioSettings()),
                _buildSection('Detection Settings', _buildDetectionSettings()),
                _buildSection('Display Settings', _buildDisplaySettings()),
                _buildSection('Accessibility', _buildAccessibilitySettings()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Settings',
          style: MyTextStyles.bold
              .copyWith(color: Colors.black, fontSize: _settings.fontSize + 4)),
      backgroundColor:
          _settings.switchMode ? const Color(0xFFFFD900) : Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
      elevation: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: (_hasChanges && !_isSaving) ? _saveSettings : null,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  )
                : Text(
                    'Save',
                    style: MyTextStyles.bold.copyWith(
                      color:
                          (_hasChanges && !_isSaving) ? Colors.black : Colors.grey,
                      fontSize: _settings.fontSize,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: MyTextStyles.bold.copyWith(
                  fontSize: _settings.fontSize + 2, color: Colors.black87)),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }

  Widget _buildAudioSettings() => Column(children: [
        SliderSettingWidget(
          title: 'Speech Rate',
          subtitle: 'Adjust speaking speed',
          value: _settings.speechRate,
          settings: _settings,
          onChanged: (v) => _updateSetting((s) => s.copyWith(speechRate: v)),
        ),
        SliderSettingWidget(
          title: 'Speech Volume',
          subtitle: 'Adjust speech volume',
          value: _settings.speechVolume,
          settings: _settings,
          onChanged: (v) => _updateSetting((s) => s.copyWith(speechVolume: v)),
        ),
        DropdownSettingWidget(
          title: 'Language',
          subtitle: 'Select speech language',
          value: _settings.language,
          settings: _settings,
          options: _languageOptions,
          onChanged: (v) {
            if (v != null) _updateSetting((s) => s.copyWith(language: v));
          },
        ),
      ]);

  Widget _buildDetectionSettings() => Column(children: [
        SliderSettingWidget(
          title: 'Confidence Threshold / Object Sensitivity',
          subtitle: 'Higher values = better accuracy, fewer detections',
          value: _settings.confidenceThreshold,
          settings: _settings,
          onChanged: (v) =>
              _updateSetting((s) => s.copyWith(confidenceThreshold: v)),
        ),
        SwitchSettingWidget(
          title: 'Direction Feedback',
          subtitle: 'Announces detected object direction (left/right)',
          value: _settings.directionMode,
          settings: _settings,
          onChanged: (v) =>
              _updateSetting((s) => s.copyWith(directionMode: v)),
        ),
      ]);

  Widget _buildDisplaySettings() => Column(children: [
        SliderSettingWidget(
          title: 'Font Size',
          subtitle: 'Adjust text size',
          value: (_settings.fontSize - 12) / 24,
          settings: _settings,
          onChanged: (v) =>
              _updateSetting((s) => s.copyWith(fontSize: 12 + (v * 24))),
        ),
      ]);

  Widget _buildAccessibilitySettings() => Column(children: [
        SwitchSettingWidget(
          title: 'High Contrast Mode',
          subtitle: 'Yellow background for low vision users',
          value: _settings.switchMode,
          settings: _settings,
          onChanged: (v) => _updateSetting((s) => s.copyWith(switchMode: v)),
        ),
      ]);
}

class _NoGlow extends ScrollBehavior {
  const _NoGlow();


  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
