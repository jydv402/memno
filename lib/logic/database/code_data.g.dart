// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CodeDataAdapter extends TypeAdapter<CodeData> {
  @override
  final int typeId = 0;

  @override
  CodeData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CodeData(
      fields[0] as int,
      (fields[1] as List).cast<String>(),
      fields[2] as String,
      fields[3] as bool,
      fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CodeData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.links)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.liked)
      ..writeByte(4)
      ..write(obj.head);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
