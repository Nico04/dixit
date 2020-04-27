import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dixit/models/_models.dart';
import 'package:dixit/helpers/tools.dart';

class DatabaseService {
  static final _rooms = Firestore.instance.collection('rooms');

  static DocumentReference _getRoomRef(String roomName) =>
    _rooms.document(roomName.normalized);

  static Future<Room> getRoom(String roomName) async =>
    Room.fromJson((await _getRoomRef(roomName).get()).data);

  static Stream<Room> getRoomStream(String roomName) =>
    _getRoomRef(roomName).snapshots().map((snapshot) => Room.fromJson(snapshot.data));

  static Future<void> saveRoom(Room room) async =>
    await _getRoomRef(room.name).setData(room.toJson());

  static Future<int> getRoomsCount() async {
    //TODO need to use a Cloud Function to keep rooms.length updated on the DB. See https://stackoverflow.com/questions/46554091/cloud-firestore-collection-count
    throw UnimplementedError();
  }

  static Future<void> savePhase(String roomName, Phase phase) async =>
    await _getRoomRef(roomName).updateData({
      'phase': phase.toJson(),
    });

  static Future<void> savePlayer(String roomName, Player player) async =>
    await _getRoomRef(roomName).updateData({
      'players.${player.name}': player.toJson()
    });
}