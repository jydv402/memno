import 'package:hive/hive.dart';

part 'code_data.g.dart';

@HiveType(typeId: 0)
class CodeData extends HiveObject {
  @HiveField(0)
  int code;

  @HiveField(1)
  List<String> links;

  @HiveField(2)
  String date;

  @HiveField(3)
  bool liked;

  @HiveField(4)
  String head;

  CodeData(this.code, this.links, this.date, this.liked, this.head);
}
