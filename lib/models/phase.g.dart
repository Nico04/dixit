// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Phase _$PhaseFromJson(Map json) {
  return Phase(
    number: json['number'] as int,
    mainPlayer: json['mainPlayer'] == null
        ? null
        : Player.fromJson((json['mainPlayer'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          )),
    sentence: json['sentence'] as String,
    cards: (json['cards'] as Map)?.map(
      (k, e) => MapEntry(
          k as String,
          e == null
              ? null
              : Player.fromJson((e as Map)?.map(
                  (k, e) => MapEntry(k as String, e),
                ))),
    ),
    votes: (json['votes'] as Map)?.map(
      (k, e) => MapEntry(
          k as String,
          (e as List)
              ?.map((e) => e == null
                  ? null
                  : Player.fromJson((e as Map)?.map(
                      (k, e) => MapEntry(k as String, e),
                    )))
              ?.toList()),
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

  writeNotNull('number', instance.number);
  writeNotNull('mainPlayer', instance.mainPlayer?.toJson());
  writeNotNull('sentence', instance.sentence);
  writeNotNull(
      'cards', instance.cards?.map((k, e) => MapEntry(k, e?.toJson())));
  writeNotNull(
      'votes',
      instance.votes
          ?.map((k, e) => MapEntry(k, e?.map((e) => e?.toJson())?.toList())));
  return val;
}
