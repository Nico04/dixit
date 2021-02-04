import 'package:device_id/device_id.dart';
import 'package:dixit/resources/resources.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'pages/_pages.dart';
import 'services/storage_service.dart';

void main() async {
  // Init
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await Firebase.initializeApp();

  // Disable print on release
  if (kReleaseMode)
    debugPrint = (message, { wrapWidth }) {};

  // Get device ID
  if (!kIsWeb)    //DeviceId plugin never returns on web. See https://github.com/TheDOme6/device_id/issues/20
    App.deviceID = await DeviceId.getID;

  // Init localisation formatter
  Intl.defaultLocale = 'fr';
  initializeDateFormatting();
  timeago.setLocaleMessages('en', timeago.FrMessages());      //Set default timeAgo local to fr

  // Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = (flutterErrorDetails) {
    debugPrint('----------------FIREBASE CRASHLYTICS----------------');
    FirebaseCrashlytics.instance.recordFlutterError(flutterErrorDetails);
  };

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
        primaryColor: AppResources.ColorRed,
        accentColor: AppResources.ColorDarkSand,
        backgroundColor: AppResources.ColorSand,
        scaffoldBackgroundColor: AppResources.ColorSand,
        cardTheme: CardTheme(
          color: AppResources.ColorOrange,
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          buttonColor: AppResources.ColorDarkSand,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      home: MainPage(),
    );
  }
}
