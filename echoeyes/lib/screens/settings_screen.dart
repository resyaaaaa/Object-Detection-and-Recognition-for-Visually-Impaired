// =====================================================
// APP FILES AND PACKAGES IMPORT
//======================================================

// Import app models, screens, widgets and services
import 'package:echoeyes/models/settings_model.dart';
import 'package:echoeyes/services/settings_service.dart';
import 'package:echoeyes/services/tts_service.dart';

// App custom fonts
import 'package:echoeyes/widgets/custom_text.dart';

// Widgets components
import 'package:echoeyes/widgets/settings/dropdown_widgets.dart';
import 'package:echoeyes/widgets/settings/slider_widgets.dart';
import 'package:echoeyes/widgets/settings/switch_toggle_widgets.dart';

// Import flutter core => UI MATERIAL DESIGN
import 'package:flutter/material.dart';

// Setting screen widget
class SettingsScreen extends StatefulWidget {
  final AppSettings settings; // Current settings rendered from previous settings

  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// =====================================================
// STATE CLASS => MANAGE SETTINGS LOGIC AND UI
//======================================================

class _SettingsScreenState extends State<SettingsScreen> {
  
  late AppSettings _settings; // store editable copy of settings
  bool _isLoading = true;     // Check if settings being loaded
  bool _hasChanges = false;   // Check if user modify settings
  bool _isSaving = false;     // Prevent multiple save actions at the same time

// ==============================================================================
//  AVAILABLE LANGUAGE OPTIONS FOR TTS => DEPENDS ON USER'S PHONE AVAILABLE TTS
//===============================================================================

  static const Map<String, String> _languageOptions = {
    'en-US': 'English (US)',
    'en-UK': 'English (UK)',
    'fr-FR': 'French (France)',
    'de-DE': 'German (Germany)',
    'es-ES': 'Spanish (Spain)',
    'zh-CN': 'Mandarin (Simplified)',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load saved settings when screen opens
  }

// =====================================================
// LOAD SETTINGS FROM LOCAL STORAGE
//======================================================

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

  // Mark settings as modified
  void _markAsChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  // Update a single setting field
  void _updateSetting(AppSettings Function(AppSettings) updater) {
    setState(() => _settings = updater(_settings));
    _markAsChanged();
  }

// =====================================================
// SAVE SETTINGS TO LOCAL STORAGE 
//======================================================

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

// =====================================================
// SHOW ERROR MESSAGE DIALOGS
//======================================================

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _settings.switchMode
            ? Colors.amberAccent[700]
            : const Color.fromARGB(255, 217, 235, 244),
        title: Text(
          'Error',
          style: MyTextStyles.bold.copyWith(
            fontSize: _settings.fontSize + 2,
            color: Colors.black,
          ),
        ),
        content: Text(
          error,
          style: MyTextStyles.medium.copyWith(
            fontSize: _settings.fontSize,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: MyTextStyles.bold.copyWith(
                fontSize: _settings.fontSize,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

// =====================================================
// CONFIRMATION ACTION WHEN USER LEAVES WITH UNSAVED MODIFIED SETTINGS
//======================================================

  Future<bool> _showUnsavedChangesDialog() async {
    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _settings.switchMode
            ? Colors.amberAccent[700]
            : const Color.fromARGB(255, 217, 235, 244),
        title: Text(
          'Unsaved Changes',
          style: MyTextStyles.bold.copyWith(
            fontSize: _settings.fontSize + 2,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Do you want to save your changes before leaving?',
          style: MyTextStyles.medium.copyWith(
            fontSize: _settings.fontSize,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Discard',
              style: MyTextStyles.bold.copyWith(
                fontSize: _settings.fontSize,
                color: Colors.red,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Save',
              style: MyTextStyles.bold.copyWith(
                fontSize: _settings.fontSize,
                color: Colors.black,
              ),
            ),
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
    // Show 'loading' indicator while settings is load
    if (_isLoading) {
      return Scaffold(
        backgroundColor: widget.settings.switchMode
            ? Colors.amberAccent[700]
            : const Color.fromARGB(255, 217, 235, 244),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.black),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_hasChanges, // Prevent back navigation if unsaved changes exist
      
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          // ignore: use_build_context_synchronously
          if (shouldPop && mounted) Navigator.pop(context);
        }
      },

// =====================================================
// CHANGE BACKGROUND, INCLUDE WIDGETS
//======================================================
      child: Scaffold(
        
        backgroundColor: _settings.switchMode
            ? Colors.amberAccent[700]
            : const Color.fromARGB(255, 217, 235, 244),
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

// =====================================================
// APPBAR WITH SAVE BUTTON
//======================================================
  PreferredSizeWidget _buildAppBar() {
    // APPBAR ==>
    return AppBar(
      title: Text(
        'Settings',
        style: MyTextStyles.bold.copyWith(
          color: Colors.black,
          fontSize: _settings.fontSize + 4,
        ),
      ),
      backgroundColor: _settings.switchMode
          ? Colors.amberAccent[700]
          : const Color.fromARGB(255, 217, 235, 244),
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
                    'Save', // SAVE BUTTON
                    style: MyTextStyles.bold.copyWith(
                      color: (_hasChanges && !_isSaving)
                          ? Colors.black
                          : Colors.grey,
                      fontSize: _settings.fontSize + 4,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

// =====================================================
// SETTINGS SECTIONS WRAPS INTO A CARD
//======================================================
  Widget _buildSection(String title, Widget content) {
    final highContrastMode = _settings.switchMode;

    return Card(
      color: highContrastMode ? Colors.amberAccent[700] : Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: MyTextStyles.bold.copyWith(
                fontSize: _settings.fontSize + 2,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSettings() => Column(
    children: [
      SliderSettingWidget(
        title: 'Speech Rate',
        subtitle: 'Adjust speaking speed',
        value: _settings.speechRate,
        settings: _settings,
        onChanged: (v) => _updateSetting((s) => s.copyWith(speechRate: v)),
      ),
      const Divider(),
      SliderSettingWidget(
        title: 'Speech Volume',
        subtitle: 'Adjust speech volume',
        value: _settings.speechVolume,
        settings: _settings,
        onChanged: (v) => _updateSetting((s) => s.copyWith(speechVolume: v)),
      ),
      const Divider(),
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
    ],
  );

  Widget _buildDetectionSettings() => Column(
    children: [
      SliderSettingWidget(
        title: 'Confidence Threshold / Object Sensitivity',
        subtitle: 'Higher values = better accuracy, fewer detections',
        value: _settings.confidenceThreshold,
        settings: _settings,
        onChanged: (v) =>
            _updateSetting((s) => s.copyWith(confidenceThreshold: v)),
      ),
      
      const Divider(),
      SwitchSettingWidget(
        title: 'Direction Feedback',
        subtitle: 'Alerts direction of the detected object',
        value: _settings.directionMode,
        settings: _settings,
        onChanged: (v) => _updateSetting((s) => s.copyWith(directionMode: v)),
      ),
    ],
  );

  Widget _buildDisplaySettings() => Column(
    children: [
      SliderSettingWidget(
        title: 'Font Size',
        subtitle: 'Adjust text size',
        value: (_settings.fontSize - 12) / 24,
        settings: _settings,
        onChanged: (v) =>
            _updateSetting((s) => s.copyWith(fontSize: 12 + (v * 24))),
      ),
    ],
  );

  Widget _buildAccessibilitySettings() => Column(
    children: [
      SwitchSettingWidget(
        title: 'High Contrast Mode',
        subtitle: 'Yellow background for low vision users',
        value: _settings.switchMode,
        settings: _settings,
        onChanged: (v) => _updateSetting((s) => s.copyWith(switchMode: v)),
      ),
    ],
  );
}

// =====================================================
// SCROLL BEHAVIOR - DISABLE GLOW EFFECT WHEN OVERSCROLL
//======================================================

class _NoGlow extends ScrollBehavior {
  const _NoGlow();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}