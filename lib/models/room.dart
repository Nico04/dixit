import 'package:json_annotation/json_annotation.dart';
import '_models.dart';

part 'room.g.dart';

@JsonSerializable()
class Room {
  final String name;
  final List<Player> players;
  final Phase phase;
  final int turn;

  Room(this.name, {List<Player> players, this.phase, int turn}) :
    this.players = players ?? List<Player>(),
    this.turn = turn ?? 0;

  bool get isGameStarted => turn > 0;

  factory Room.fromJson(Map<dynamic, dynamic> json) => json == null ? null : _$RoomFromJson(json);
  Map<String, dynamic> toJson() => _$RoomToJson(this);
}