import 'package:json_annotation/json_annotation.dart';
import '_models.dart';

part 'room.g.dart';

@JsonSerializable()
class Room {
  final String name;    //Room name, may differ from the database key which is normalized
  final Map<String, Player> players;    // <playerName, player>
  Phase phase;
  int turn;

  Player get mainPlayer => phase != null ? players[phase.mainPlayerName] : null;

  Room(this.name, {Map<String, Player> players, this.phase, int turn}) :
    this.players = players ?? Map<String, Player>(),
    this.turn = turn ?? 0;

  bool get isGameStarted => turn > 0;

  factory Room.fromJson(Map<String, dynamic> json) => json == null ? null : _$RoomFromJson(json);
  Map<String, dynamic> toJson() => _$RoomToJson(this);
}