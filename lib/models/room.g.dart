// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Room _$RoomFromJson(Map<String, dynamic> json) {
  return Room(
    json['name'] as String,
    players: (json['players'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          k, e == null ? null : Player.fromJson(e as Map<String, dynamic>)),
    ),
    phase: json['phase'] == null
        ? null
        : Phase.fromJson(json['phase'] as Map<String, dynamic>),
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
  writeNotNull(
      'players', instance.players?.map((k, e) => MapEntry(k, e?.toJson())));
  writeNotNull('phase', instance.phase?.toJson());
  writeNotNull('turn', instance.turn);
  return val;
}
