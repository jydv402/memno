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

  // toJSON function
  Map<String, dynamic> toJSON() {
    return {
      'code': code,
      'head': head,
      'links': links,
      'liked': liked,
      'date': date,
    };
  }

  // fromJSON fucntion
  factory CodeData.fromJSON(Map<String, dynamic> json) {
    return CodeData(
      json['code'] as int,
      List<String>.from(json['links'] as List),
      json['date'] as String,
      json['liked'] as bool,
      json['head'] as String,
    );
  }
}
