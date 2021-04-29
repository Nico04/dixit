import 'package:flutter/foundation.dart';

/// Information on the runtime environment.
/// Indicate on which environment the app is executed on.
///
/// Because [dart:io] is not available on web, [dart:io.Platform] is not accessible.
/// [defaultTargetPlatform] returns the underlying platform, whereas [RuntimeInfo] indicate the running environment.
/// For instance, if app runs on a browser in Android, [defaultTargetPlatform] will return Android and [RuntimeInfo] web.
class RuntimeInfo  {
  /// Whether app is executed on native Android
  static final bool isNativeAndroid = !isWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Whether app is executed on native iOS
  static final bool isNativeIOS = !isWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether app is executed on a web browser
  static final bool isWeb = kIsWeb;
}
