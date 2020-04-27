import 'package:dixit/models/_models.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dixit/helpers/tools.dart';

class DatabaseService {
  static final _root = FirebaseDatabase.instance.reference();

  static DatabaseReference _getRoomRef(String roomName) =>
    _root.child('rooms').child(roomName.normalized);

  static Future<Room> getRoom(String roomName) async =>
    Room.fromJson((await _getRoomRef(roomName).once()).value);

  static Stream<Room> getRoomStream(String roomName) {
    var ref = _getRoomRef(roomName);
    ref.keepSynced(true);
    return _getRoomRef(roomName).onValue.map((event) => Room.fromJson(event.snapshot.value));
  }

  static Future<void> saveRoom(Room room) async =>
    await _getRoomRef(room.name).update(room.toJson());

  static Future<int> getRoomsCount() async {
    //TODO need to use a Cloud Function to keep rooms.length updated on the DB
    throw UnimplementedError();
  }

  static Future<void> savePhase(String roomName, Phase phase) async =>
    await _getRoomRef(roomName).child('phase').update(phase.toJson());

  static Future<void> savePlayer(String roomName, Player player) async =>
    await _getRoomRef(roomName).child('players').child(player.name).update(player.toJson());
}