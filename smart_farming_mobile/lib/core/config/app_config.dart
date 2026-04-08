class AppConfig {
  const AppConfig._();

  static const String appName = 'Smart Farming Assistant';
  static const String baseUrl =
      'https://smartfarmingassistant-pw45.onrender.com';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 20);

  static const List<String> defaultStates = <String>[
    'Tamil Nadu',
    'Karnataka',
    'Kerala',
    'Andhra Pradesh',
    'Telangana',
    'Maharashtra',
    'Gujarat',
    'Punjab',
    'Uttar Pradesh',
    'Madhya Pradesh',
  ];
}
