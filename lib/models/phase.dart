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
  Map<String, int> playedCards;         // <playerName, cardID> - Order is NOT guaranteed (because of Firestore)
  final Map<int, List<String>> votes;   // <cardID, List<playerName>> - Order is NOT guaranteed (because of Firestore)
  Map<String, int> scores;    // <playerName, score> : Score for this phase only

  Phase(this.storytellerName, { int number, this.sentence, Map<String, int> playedCards, Map<int, List<String>> votes, this.scores }) :
    this.number = number ?? 1,
    this.playedCards = playedCards ?? Map<String, int>(),
    this.votes = votes ?? Map<int, List<String>>();

  factory Phase.fromJson(Map<String, dynamic> json) => json == null ? null : _$PhaseFromJson(json);
  Map<String, dynamic> toJson() => _$PhaseToJson(this);
}