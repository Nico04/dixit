import 'package:json_annotation/json_annotation.dart';

part 'phase.g.dart';

@JsonSerializable()
class Phase {
  final String mainPlayerName;
  int number;
  String sentence;
  final Map<String, String> playedCards;  // <playerName, card>
  final Map<String, List<String>> votes;  // <card, List<playerName>>

  Phase(this.mainPlayerName, {int number, this.sentence, Map<String, String> playedCards, Map<String, List<String>> votes}) :
    this.number = number ?? 1,
    this.playedCards = playedCards ?? Map<String, String>(),
    this.votes = votes ?? Map<String, List<String>>();

  factory Phase.fromJson(Map<dynamic, dynamic> json) => json == null ? null : _$PhaseFromJson(json);
  Map<String, dynamic> toJson() => _$PhaseToJson(this);
}