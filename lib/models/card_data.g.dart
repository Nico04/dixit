// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardData _$CardDataFromJson(Map<String, dynamic> json) {
  return CardData(
    json['id'] as int,
    json['filename'] as String,
    json['blurHash'] as String,
  );
}

Map<String, dynamic> _$CardDataToJson(CardData instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('filename', instance.filename);
  writeNotNull('blurHash', instance.blurHash);
  return val;
}
