// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Room _$RoomFromJson(Map json) {
  return Room(
    json['name'] as String,
    players: (json['players'] as List)
        ?.map((e) => e == null
            ? null
            : Player.fromJson((e as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )))
        ?.toList(),
    phase: json['phase'] == null
        ? null
        : Phase.fromJson((json['phase'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          )),
    turn: json['turn'] as int,
  );
}

Map<String, dynamic> _$RoomToJson(Room instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('players', instance.players?.map((e) => e?.toJson())?.toList());
  writeNotNull('phase', instance.phase?.toJson());
  writeNotNull('turn', instance.turn);
  return val;
}
