// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Phase _$PhaseFromJson(Map json) {
  return Phase(
    json['mainPlayerName'] as String,
    number: json['number'] as int,
    sentence: json['sentence'] as String,
    playedCards: (json['playedCards'] as Map)?.map(
      (k, e) => MapEntry(k as String, e as String),
    ),
    votes: (json['votes'] as Map)?.map(
      (k, e) =>
          MapEntry(k as String, (e as List)?.map((e) => e as String)?.toList()),
    ),
  );
}

Map<String, dynamic> _$PhaseToJson(Phase instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('mainPlayerName', instance.mainPlayerName);
  writeNotNull('number', instance.number);
  writeNotNull('sentence', instance.sentence);
  writeNotNull('playedCards', instance.playedCards);
  writeNotNull('votes', instance.votes);
  return val;
}
