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
      updatedAt: fields[5] as int?,
      updatedBy: fields[6] as String?,
      rev: fields[7] as int?,
      deleted: fields[8] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, CodeData obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.links)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.liked)
      ..writeByte(4)
      ..write(obj.head)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.updatedBy)
      ..writeByte(7)
      ..write(obj.rev)
      ..writeByte(8)
      ..write(obj.deleted);
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
