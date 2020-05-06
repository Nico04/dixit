import 'package:device_id/device_id.dart';
import 'package:dixit/resources/resources.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'pages/_pages.dart';
import 'services/storage_service.dart';

void main() async {
  // Init
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  // Get device ID
  if (!kIsWeb)    //DeviceId plugin never returns on web. See https://github.com/TheDOme6/device_id/issues/20
    App.deviceID = await DeviceId.getID;

  // Init localisation formatter
  Intl.defaultLocale = 'fr';
  initializeDateFormatting();

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
      theme: ThemeData(
        primaryColor: AppResources.ColorSand,
        accentColor: AppResources.ColorRed,
        backgroundColor: AppResources.ColorOrange,
        scaffoldBackgroundColor: AppResources.ColorOrange,
        cardTheme: CardTheme(
          color: AppResources.ColorSand,
        )
      ),
      home: MainPage(),
    );
  }
}
