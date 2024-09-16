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

  String getDateForCode(int code) {
    final codeData =
        _codeBox.values.firstWhere((codeData) => codeData.code == code);
    //orElse: () => CodeData(code, [], date, liked, head));

    return codeData.date;
  }

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

  String getHeadForCode(int code) {
    final codeData =
        _codeBox.values.firstWhere((codeData) => codeData.code == code);
    //orElse: () => CodeData(code, [], date, liked, head));
    return codeData.head;
  }

  Future<void> addLink(int code, String link) async {
    final codeData =
        _codeBox.values.firstWhere((codeData) => codeData.code == code);
    //orElse: () => CodeData(code, [], date, liked, head));
    codeData.links.add(link);
    await codeData.save();
    notifyListeners();
  }

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
