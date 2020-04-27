import 'package:json_annotation/json_annotation.dart';

part 'player.g.dart';

@JsonSerializable()
class Player {
  final String name;
  List<String> cards;
  final int score;

  Player(this.name, {this.cards, int score}) :
    this.score = score ?? 0;

  factory Player.fromJson(Map<dynamic, dynamic> json) => json == null ? null : _$PlayerFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerToJson(this);
}