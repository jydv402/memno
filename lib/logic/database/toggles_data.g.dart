// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toggles_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TogglesDataAdapter extends TypeAdapter<TogglesData> {
  @override
  final int typeId = 1;

  @override
  TogglesData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TogglesData(
      darkMode: fields[0] as bool,
      compactHeader: fields[1] as bool,
      themeMode: fields[2] as int?,
      saveImagesLocally: fields[3] == null ? true : fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TogglesData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.darkMode)
      ..writeByte(1)
      ..write(obj.compactHeader)
      ..writeByte(2)
      ..write(obj.themeMode)
      ..writeByte(3)
      ..write(obj.saveImagesLocally);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TogglesDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
