import 'package:hive/hive.dart';

part 'preview_data.g.dart';

@HiveType(typeId: 2)
class PreviewDataModel {
  @HiveField(0)
  final String? title;

  @HiveField(1)
  final String? description;

  @HiveField(2)
  final String? image;

  @HiveField(3)
  final double? imageHeight;

  @HiveField(4)
  final double? imageWidth;

  @HiveField(5)
  final String? link;

  @HiveField(6)
  final String? localImagePath;

  PreviewDataModel({
    this.title,
    this.description,
    this.image,
    this.imageHeight,
    this.imageWidth,
    this.link,
    this.localImagePath,
  });
}
