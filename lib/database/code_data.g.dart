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
    );
  }

  @override
  void write(BinaryWriter writer, CodeData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.links);
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
