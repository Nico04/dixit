import 'dart:collection';
import 'package:dixit/helpers/tools.dart';
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
  LinkedHashMap<String, int> playedCards;     // <playerName, cardID> - Ordered by CardID (to avoid board cards order changing when room update (happens on Web version), because firebase doesn't guarantee order)
  final Map<int, List<String>> votes;   // <cardID, List<playerName>> - Order is NOT guaranteed (because of Firestore)
  Map<String, int> scores;    // <playerName, score> : Score for this phase only

  Phase(this.storytellerName, { int number, this.sentence, Map<String, int> playedCards, Map<int, List<String>> votes, this.scores }) :
    this.number = number ?? 1,
    this.playedCards = (playedCards ?? LinkedHashMap<String, int>()).sorted((e1, e2) => e1.value.compareTo(e2.value)),    // Force sort by cardID, as order in NOT guaranteed by Firestore
    this.votes = votes ?? Map<int, List<String>>();

  factory Phase.fromJson(Map<String, dynamic> json) => json == null ? null : _$PhaseFromJson(json);
  Map<String, dynamic> toJson() => _$PhaseToJson(this);
}