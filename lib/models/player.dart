import 'package:json_annotation/json_annotation.dart';

part 'player.g.dart';

@JsonSerializable()
class Player {
  final String name;    //OPTI remove this from json, because it's on the key already
  List<String> cards;
  int score;

  Player(this.name, {this.cards, int score}) :
    this.score = score ?? 0;

  factory Player.fromJson(Map<String, dynamic> json) => json == null ? null : _$PlayerFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerToJson(this);
}