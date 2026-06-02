// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preview_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PreviewDataModelAdapter extends TypeAdapter<PreviewDataModel> {
  @override
  final int typeId = 2;

  @override
  PreviewDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PreviewDataModel(
      title: fields[0] as String?,
      description: fields[1] as String?,
      image: fields[2] as String?,
      imageHeight: fields[3] as double?,
      imageWidth: fields[4] as double?,
      link: fields[5] as String?,
      localImagePath: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PreviewDataModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.image)
      ..writeByte(3)
      ..write(obj.imageHeight)
      ..writeByte(4)
      ..write(obj.imageWidth)
      ..writeByte(5)
      ..write(obj.link)
      ..writeByte(6)
      ..write(obj.localImagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
