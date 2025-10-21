class AppSettings {
  double speechRate;
  String language;
  double speechVolume;
  bool switchMode;
  double confidenceThreshold;
  double fontSize;
  bool directionMode;

  AppSettings({
    this.speechRate = 0.5,
    this.language = 'en-US',
    this.speechVolume = 1.0,
    this.switchMode = false,
    this.confidenceThreshold = 0.5,
    this.fontSize = 13.0,
    this.directionMode = false,
  });

  AppSettings copyWith({
    double? speechRate,
    String? language,
    double? speechVolume,
    bool? switchMode,
    double? confidenceThreshold,
    double? fontSize,
    bool? directionMode,
  }) {
    return AppSettings(
      speechRate: speechRate ?? this.speechRate,
      language: language ?? this.language,
      speechVolume: speechVolume ?? this.speechVolume,
      switchMode: switchMode ?? this.switchMode,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      fontSize: fontSize ?? this.fontSize,
      directionMode: directionMode ?? this.directionMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'speechRate': speechRate,
    'language': language,
    'speechVolume': speechVolume,
    'switchMode': switchMode,
    'confidenceThreshold': confidenceThreshold,
    'fontSize': fontSize,
    'directionMode' : directionMode,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.5,
      language: json['language'] as String? ?? 'en-US',
      speechVolume: (json['speechVolume'] as num?)?.toDouble() ?? 1.0,
      switchMode: json['switchMode'] as bool? ?? false,
      confidenceThreshold:
          (json['confidenceThreshold'] as num?)?.toDouble() ?? 0.5,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 13.0,
      directionMode: json['directionMode'] as bool? ?? false,
    );
  }
}
