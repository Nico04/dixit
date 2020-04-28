import 'package:json_annotation/json_annotation.dart';

part 'card_data.g.dart';

@JsonSerializable()
class CardData {
  final int id;
  final String filename;
  final String blurHash;

  const CardData(this.id, this.filename, this.blurHash);

  factory CardData.fromJson(Map<String, dynamic> json) => _$CardDataFromJson(json);
  Map<String, dynamic> toJson( instance) => _$CardDataToJson(this);
}