import 'dart:math';
import 'package:flutter/material.dart';
import 'package:memno/database/code_data.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CodeGen extends ChangeNotifier {
  late Box<CodeData> _codeBox;
  bool _isReady = false;
  final bool liked = false;
  final String date = DateTime.now().toString();

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

    await _codeBox.add(CodeData(code, [], date, liked));
    notifyListeners();
  }

  Future<void> clearList(int code) async {
    var key =
        _codeBox.keys.firstWhere((key) => _codeBox.get(key)!.code == code);
    await _codeBox.delete(key);
    notifyListeners();
  }

  String getDateForCode(int code) {
    final codeData = _codeBox.values.firstWhere(
        (codeData) => codeData.code == code,
        orElse: () => CodeData(code, [], date, liked));

    return codeData.date;
  }

  bool getLikeForCode(int code) {
    final codeData = _codeBox.values.firstWhere(
        (codeData) => codeData.code == code,
        orElse: () => CodeData(code, [], date, liked));
    return codeData.liked;
  }

  //toggle like
  Future<void> toggleLike(int code) async {
    final codeData = _codeBox.values.firstWhere(
        (codeData) => codeData.code == code,
        orElse: () => CodeData(code, [], date, liked));
    codeData.liked = !codeData.liked;
    await codeData.save();
    notifyListeners();
  }

  List<String> getLinksForCode(int code) {
    final codeData = _codeBox.values.firstWhere(
        (codeData) => codeData.code == code,
        orElse: () => CodeData(code, [], date, liked));

    return codeData.links;
  }

  Future<void> addLink(int code, String link) async {
    final codeData = _codeBox.values.firstWhere(
        (codeData) => codeData.code == code,
        orElse: () => CodeData(code, [], date, liked));
    codeData.links.add(link);
    await codeData.save();
    notifyListeners();
  }

  Future<void> editLink(int code, int index, String newLink) async {
    final codeData = _codeBox.values.firstWhere(
        (codeData) => codeData.code == code,
        orElse: () => CodeData(code, [], date, liked));
    if (codeData.links.length > index) {
      codeData.links[index] = newLink;
      await codeData.save();
      notifyListeners();
    }
  }

  Future<void> deleteLink(int code, int index) async {
    final codeData = _codeBox.values.firstWhere(
        (codeData) => codeData.code == code,
        orElse: () => CodeData(code, [], date, liked));
    if (codeData.links.length > index) {
      codeData.links.removeAt(index);
      codeData.save();
      notifyListeners();
    }
  }

  void display() {
    print(_codeBox.values
        .map((codeData) => {
              codeData.code: codeData.links,
              "Date": codeData.date,
              "liked": codeData.liked
            })
        .toList());
  }
}
