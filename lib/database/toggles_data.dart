import 'package:hive/hive.dart';

part 'toggles_data.g.dart';

@HiveType(typeId: 1)
class TogglesData extends HiveObject {
  @HiveField(0)
  bool darkMode;

  TogglesData({this.darkMode = false});
}
