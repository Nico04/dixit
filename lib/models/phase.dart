import 'package:json_annotation/json_annotation.dart';

part 'phase.g.dart';

@JsonSerializable()
class Phase {
  static const Phase1_storytellerSentence = 1;
  static const Phase2_cardSelect = 2;
  static const Phase3_vote = 3;
  static const Phase4_scores = 4;

  final String storytellerName;   // Player name of the storyteller
  int number;
  String sentence;                // Storyteller's sentence
  final Map<String, String> playedCards;  // <playerName, card>
  final Map<String, List<String>> votes;  // <card, List<playerName>>

  Phase(this.storytellerName, {int number, this.sentence, Map<String, String> playedCards, Map<String, List<String>> votes}) :
    this.number = number ?? 1,
    this.playedCards = playedCards ?? Map<String, String>(),
    this.votes = votes ?? Map<String, List<String>>();

  factory Phase.fromJson(Map<String, dynamic> json) => json == null ? null : _$PhaseFromJson(json);
  Map<String, dynamic> toJson() => _$PhaseToJson(this);
}