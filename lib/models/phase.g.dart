// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Phase _$PhaseFromJson(Map<String, dynamic> json) {
  return Phase(
    json['storytellerName'] as String,
    number: json['number'] as int,
    sentence: json['sentence'] as String,
    playedCards: (json['playedCards'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as int),
    ),
    votes: (json['votes'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          int.parse(k), (e as List)?.map((e) => e as String)?.toList()),
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

  writeNotNull('storytellerName', instance.storytellerName);
  writeNotNull('number', instance.number);
  writeNotNull('sentence', instance.sentence);
  writeNotNull('playedCards', instance.playedCards);
  writeNotNull(
      'votes', instance.votes?.map((k, e) => MapEntry(k.toString(), e)));
  return val;
}
