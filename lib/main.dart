import 'package:device_id/device_id.dart';
import 'package:flutter/material.dart';

import 'pages/_pages.dart';
import 'services/storage_service.dart';

void main() async {
  // Init
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  App.deviceID = await DeviceId.getID;

  // Start app
  runApp(App());
}

class App extends StatelessWidget {
  // Device's uid
  static String deviceID;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dixit',
      home: MainPage(),
    );
  }
}
