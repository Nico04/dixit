import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _playerNameKey = "playerName";

  static SharedPreferences _storage;

  static Future<void> init() async =>
    _storage = await SharedPreferences.getInstance();

  static Future<void> savePlayerName(String value) async =>
    _storage.setString(_playerNameKey, value);

  static String readPlayerName() =>
    _storage.getString(_playerNameKey);
}