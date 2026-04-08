import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.init();

  runApp(
    DevicePreview(
      enabled: kDebugMode,
      builder: (_) => const SmartFarmingMobileApp(),
    ),
  );
}
