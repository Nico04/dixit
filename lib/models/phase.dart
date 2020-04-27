import 'package:json_annotation/json_annotation.dart';
import '_models.dart';

part 'phase.g.dart';

@JsonSerializable()
class Phase {
  final int number;
  final Player mainPlayer;
  final String sentence;
  final Map<String, Player> cards;
  final Map<String, List<Player>> votes;

  Phase({this.number, this.mainPlayer, this.sentence, this.cards, this.votes});

  factory Phase.fromJson(Map<dynamic, dynamic> json) => json == null ? null : _$PhaseFromJson(json);
  Map<String, dynamic> toJson() => _$PhaseToJson(this);
}