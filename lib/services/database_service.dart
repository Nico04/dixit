import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  static final _root = FirebaseDatabase.instance.reference();

  static Future<Room> jointOrCreateRoom() {

  }

  static Future<int> getRoomsCount() async {
    //TODO
    /*var snapshot = await _root*/
  }
}