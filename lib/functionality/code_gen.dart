import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:memno/database/code_data.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CodeGen extends ChangeNotifier {
  late Box<CodeData> _codeBox;
  bool _isReady = false;
  final bool liked = false;
  final String head = "Untitled";

  CodeGen() {
    init();
  }

  //initializes hive
  Future<void> init() async {
    Hive.registerAdapter(CodeDataAdapter());
    _codeBox = await Hive.openBox<CodeData>('codeData');
    _isReady = true;
    notifyListeners();
  }

  bool get isReady => _isReady;

  List<int> get codeList {
    return _codeBox.values.map((codeData) => codeData.code).toList();
  }

  //generates 6 digit code
  Future<void> generateCode() async {
    var rnd = Random();
    int code;
    do {
      code = 100000 + (rnd.nextInt(900000));
    } while (_codeBox.values.any((codeData) => codeData.code == code));

    await _codeBox
        .add(CodeData(code, [], DateTime.now().toString(), liked, head));
    notifyListeners();
  }

  //deletes a specific code
  Future<void> clearList(int code) async {
    var key =
        _codeBox.keys.firstWhere((key) => _codeBox.get(key)!.code == code);
    await _codeBox.delete(key);
    notifyListeners();
  }

  //return the lenght of link list
  int getLinkListLength(int code) {
    final codeData =
        _codeBox.values.firstWhere((codeData) => codeData.code == code);
    //orElse: () => CodeData(code, [], date, liked, head));
    return codeData.links.length;
  }

  //returns date
  String getDateForCode(int code) {
    final codeData =
        _codeBox.values.firstWhere((codeData) => codeData.code == code);
    //orElse: () => CodeData(code, [], date, liked, head));

    return codeData.date;
  }

  //returns liked status
  bool getLikeForCode(int code) {
    final codeData =
        _codeBox.values.firstWhere((codeData) => codeData.code == code);
    //orElse: () => CodeData(code, [], date, liked, head));
    return codeData.liked;
  }

  //toggle like
  Future<void> toggleLike(int code) async {
    final codeData =
        _codeBox.values.firstWhere((codeData) => codeData.code == code);
    //orElse: () => CodeData(code, [], date, liked, head));
    codeData.liked = !codeData.liked;
    await codeData.save();
    notifyListeners();
  }

  //returns list of links
  List<String> getLinksForCode(int code) {
    final codeData =
        _codeBox.values.firstWhere((codeData) => codeData.code == code);
    //orElse: () => CodeData(code, [], date, liked, head));

    return codeData.links;
  }

  //Add heading text
  Future<void> addHead(int code, String head) async {
    final codeData =
        _codeBox.values.firstWhere((codeData) => codeData.code == code);
    //orElse: () => CodeData(code, [], date, liked, head));
    codeData.head = head;
    await codeData.save();
    notifyListeners();
  }

  //returns heading text
  String getHeadForCode(int code) {
    final codeData =
        _codeBox.values.firstWhere((codeData) => codeData.code == code);
    //orElse: () => CodeData(code, [], date, liked, head));
    return codeData.head;
  }

  //Add link to a specific code
  Future<void> addLink(int code, String link) async {
    final codeData =
        _codeBox.values.firstWhere((codeData) => codeData.code == code);
    //orElse: () => CodeData(code, [], date, liked, head));
    codeData.links.add(link);
    await codeData.save();
    notifyListeners();
  }

  //Edit links within a specific code
  Future<void> editLink(int code, int index, String newLink) async {
    final codeData =
        _codeBox.values.firstWhere((codeData) => codeData.code == code);
    //orElse: () => CodeData(code, [], date, liked, head));
    if (codeData.links.length > index) {
      codeData.links[index] = newLink;
      await codeData.save();
      notifyListeners();
    }
  }

  //Delete link within a specific code
  Future<void> deleteLink(int code, int index) async {
    final codeData =
        _codeBox.values.firstWhere((codeData) => codeData.code == code);
    //orElse: () => CodeData(code, [], date, liked, head));
    if (codeData.links.length > index) {
      codeData.links.removeAt(index);
      codeData.save();
      notifyListeners();
    }
  }
}
