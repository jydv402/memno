import 'package:hive/hive.dart';

part 'code_data.g.dart';

@HiveType(typeId: 0)
class CodeData extends HiveObject {
  @HiveField(0)
  int code;

  @HiveField(1)
  List<String> links;

  CodeData(this.code, this.links);
}
