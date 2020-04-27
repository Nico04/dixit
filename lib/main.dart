import 'package:flutter/material.dart';

import 'pages/_pages.dart';
import 'services/storage_service.dart';

void main() async {
  // Init
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  // Start app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dixit',
      home: MainPage(),
    );
  }
}
