// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Player _$PlayerFromJson(Map<String, dynamic> json) {
  return Player(
    json['deviceID'] as String,
    json['name'] as String,
    cards: (json['cards'] as List)?.map((e) => e as int)?.toList(),
    score: json['score'] as int,
  );
}

Map<String, dynamic> _$PlayerToJson(Player instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('deviceID', instance.deviceID);
  writeNotNull('name', instance.name);
  writeNotNull('cards', instance.cards);
  writeNotNull('score', instance.score);
  return val;
}
