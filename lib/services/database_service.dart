import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dixit/models/_models.dart';
import 'package:dixit/utils/_utils.dart';

class DatabaseService {
  // OPTI for all final fields, don't upload them at each update, because they didn't change
  static final _rooms = FirebaseFirestore.instance.collection('rooms');

  static DocumentReference _getRoomRef(String roomName) =>
    _rooms.doc(roomName.normalized);

  static Future<Room> getRoom(String roomName) async =>
    Room.fromJson((await _getRoomRef(roomName).get()).data());

  static Stream<Room> getRoomStream(String roomName) =>
    _getRoomRef(roomName).snapshots().map((snapshot) => Room.fromJson(snapshot.data()));

  static Future<void> saveRoom(Room room) async =>
    await _getRoomRef(room.name).set(room.toJson());

  static Future<void> savePhase(String roomName, Phase phase) async =>
    await _getRoomRef(roomName).set({
      'phase': phase.toJson(),
    }, SetOptions(merge: true));
  
  static Future<void> addVote(String roomName, String playerName, int card) async =>
    await _getRoomRef(roomName).update({
      'phase.votes.$card': FieldValue.arrayUnion([playerName]),
    });

  static Future<void> savePhaseNumber(String roomName, int phaseNumber) async =>
    await _getRoomRef(roomName).update({
      'phase.number': phaseNumber,
    });

  static Future<void> savePlayer(String roomName, Player player) async =>
    await _getRoomRef(roomName).update({
      'players.${player.name}': player.toJson()
    });

  ///
  /// return null in [editFunction] callback to ignore saving (no modifications)
  static Future<void> editRoomInTransaction(String roomName, Room editFunction(Room room)) async {
    Object exception;

    // Use a firebase transaction to make sure data is relevant (for when multiple users editing the room at the same time)
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) async {
      // Get room from DB
      final roomRef = _getRoomRef(roomName);
      final roomJson = (await transaction.get(roomRef)).data();
      var room = Room.fromJson(roomJson);

      // Edit room object
      Room editedRoom;
      try {
        editedRoom = editFunction(room);
      } catch (e) {
        exception = e;
      }

      // Save edited room to DB
      if (editedRoom != null) {
        transaction.set(roomRef, editedRoom.toJson());
        room = editedRoom;
      } else {
        transaction.update(roomRef, {});    //Without this it throws : PlatformException(Every document read in a transaction must also be written in that transaction., null)
      }
    });

    if (exception != null)
      throw exception;
  }
}