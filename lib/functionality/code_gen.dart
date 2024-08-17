import 'dart:math';
import 'package:flutter/material.dart';
import 'package:memno/database/code_data.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CodeGen extends ChangeNotifier {
  late Box<CodeData> _codeBox;
  bool _isReady = false;

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

  List<int> get codeList =>
      _codeBox.values.map((codeData) => codeData.code).toList();

  Future<void> generateCode() async {
    var rnd = Random();
    int code;
    do {
      code = 100000 + (rnd.nextInt(900000));
    } while (_codeBox.values.any((codeData) => codeData.code == code));

    await _codeBox.add(CodeData(code, []));
    notifyListeners();
  }

  Future<void> clearList(int code) async {
    var key =
        _codeBox.keys.firstWhere((key) => _codeBox.get(key)!.code == code);
    await _codeBox.delete(key);
    notifyListeners();
  }

  List<String> getLinksForCode(int code) {
    final codeData = _codeBox.values.firstWhere(
        (codeData) => codeData.code == code,
        orElse: () => CodeData(code, []));

    return codeData.links;
  }

  Future<void> addLink(int code, String link) async {
    final codeData = _codeBox.values.firstWhere(
        (codeData) => codeData.code == code,
        orElse: () => CodeData(code, []));
    codeData.links.add(link);
    await codeData.save();
    notifyListeners();
  }

  Future<void> editLink(int code, int index, String newLink) async {
    final codeData = _codeBox.values.firstWhere(
        (codeData) => codeData.code == code,
        orElse: () => CodeData(code, []));
    if (codeData.links.length > index) {
      codeData.links[index] = newLink;
      await codeData.save();
      notifyListeners();
    }
  }

  Future<void> deleteLink(int code, int index) async {
    final codeData = _codeBox.values.firstWhere(
        (codeData) => codeData.code == code,
        orElse: () => CodeData(code, []));
    if (codeData.links.length > index) {
      codeData.links.removeAt(index);
      codeData.save();
      notifyListeners();
    }
  }

  void display() {
    print(_codeBox.values
        .map((codeData) => {codeData.code: codeData.links})
        .toList());
  }
}
