import 'package:dixit/helpers/tools.dart';
import 'package:json_annotation/json_annotation.dart';
import '_models.dart';

part 'room.g.dart';

@JsonSerializable()
class Room {
  final String name;    // Room name, may differ from the database key which is normalized
  final List<int> cardDeck;   // Cards left in the pile/deck    // TODO change to drawnCards : the max used cards in a game is around 100, so it's more efficient to store drawnCards instead of left cards
  final Map<String, Player> players;    // <playerName, player> - Order in NOT guaranteed (because of Firestore)
  Phase phase;
  Phase previousPhase;  // Keep a ref to previous phase when starting a new turn
  int turn;

  //TODO use Firestore Timestamp with FieldValue.serverTimestamp(). But it breaks fromJson.
  // see https://stackoverflow.com/questions/60793441/how-do-i-resolve-type-timestamp-is-not-a-subtype-of-type-string-in-type-cast
  // see https://github.com/google/built_value.dart/issues/543
  @JsonKey(fromJson: dateFromString, toJson: dateToString)
  final DateTime startDate;

  @JsonKey(fromJson: dateFromString, toJson: dateToString)
  DateTime endDate;

  Room(this.name, this.cardDeck, {Map<String, Player> players, this.phase, this.previousPhase, int turn, DateTime startDate}) :
    this.players = players ?? Map<String, Player>(),
    this.turn = turn ?? 0,
    this.startDate = startDate ?? DateTime.now();

  bool get isGameStarted => turn > 0;

  factory Room.fromJson(Map<String, dynamic> json) => json == null ? null : _$RoomFromJson(json);
  Map<String, dynamic> toJson() => _$RoomToJson(this);
}