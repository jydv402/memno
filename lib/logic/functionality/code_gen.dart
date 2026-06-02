import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:memno/logic/database/code_data.dart';

class CodeGen extends ChangeNotifier {
  late Box<CodeData> _codeBox;
  bool _isReady = false;

  CodeGen() {
    init();
  }

  //initializes hive
  Future<void> init() async {
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

    await _codeBox.add(
      CodeData(code, [], DateTime.now().toString(), false, "Untitled"),
    );
    notifyListeners();
  }

  //deletes a specific code
  Future<void> clearList(int code) async {
    final key = _codeBox.keys.cast<dynamic>().firstWhere(
      (key) => _codeBox.get(key)?.code == code,
      orElse: () => null,
    );
    if (key == null) return;
    await _codeBox.delete(key);
    notifyListeners();
  }

  //return the lenght of link list
  int getLinkListLength(int code) {
    final codeData = _codeBox.values.firstWhere(
      (codeData) => codeData.code == code,
      orElse: () => CodeData(code, [], "", false, ""),
    );
    //orElse: () => CodeData(code, [], date, liked, head));
    return codeData.links.length;
  }

  //returns date
  String getDateForCode(int code) {
    final codeData = _codeBox.values.firstWhere(
      (codeData) => codeData.code == code,
      orElse: () => CodeData(code, [], "", false, ""),
    );
    //orElse: () => CodeData(code, [], date, liked, head));

    return codeData.date;
  }

  //returns liked status
  bool getLikeForCode(int code) {
    final codeData = _codeBox.values.firstWhere(
      (codeData) => codeData.code == code,
      orElse: () => CodeData(code, [], "", false, ""),
    );
    //orElse: () => CodeData(code, [], date, liked, head));
    return codeData.liked;
  }

  //toggle like
  Future<void> toggleLike(int code) async {
    final codeData = _codeBox.values
        .where((codeData) => codeData.code == code)
        .firstOrNull;
    if (codeData == null) return;
    codeData.liked = !codeData.liked;
    await codeData.save();
    notifyListeners();
  }

  //returns list of links
  List<String> getLinksForCode(int code) {
    final codeData = _codeBox.values.firstWhere(
      (codeData) => codeData.code == code,
      orElse: () => CodeData(code, [], "", false, ""),
    );
    //orElse: () => CodeData(code, [], date, liked, head));

    return codeData.links;
  }

  //Add heading text
  Future<void> addHead(int code, String head) async {
    final codeData = _codeBox.values
        .where((codeData) => codeData.code == code)
        .firstOrNull;
    if (codeData == null) return;
    codeData.head = head;
    codeData.date = DateTime.now().toString();
    await codeData.save();
    notifyListeners();
  }

  //returns heading text
  String getHeadForCode(int code) {
    final codeData = _codeBox.values.firstWhere(
      (codeData) => codeData.code == code,
      orElse: () => CodeData(code, [], "", false, "Untitled"),
    );
    //orElse: () => CodeData(code, [], date, liked, head));
    return codeData.head;
  }

  //Add link to a specific code
  Future<void> addLink(int code, String link) async {
    final codeData = _codeBox.values
        .where((codeData) => codeData.code == code)
        .firstOrNull;
    if (codeData == null) return;
    codeData.links.add(link);
    codeData.date = DateTime.now().toString();
    await codeData.save();
    notifyListeners();
  }

  //Edit links within a specific code
  Future<void> editLink(int code, int index, String newLink) async {
    final codeData = _codeBox.values
        .where((codeData) => codeData.code == code)
        .firstOrNull;
    if (codeData == null) return;
    if (codeData.links.length > index) {
      codeData.links[index] = newLink;
      codeData.date = DateTime.now().toString();
      await codeData.save();
      notifyListeners();
    }
  }

  //Delete link within a specific code
  Future<void> deleteLink(int code, int index) async {
    final codeData = _codeBox.values
        .where((codeData) => codeData.code == code)
        .firstOrNull;
    if (codeData == null) return;
    if (codeData.links.length > index) {
      codeData.links.removeAt(index);
      codeData.date = DateTime.now().toString();
      await codeData.save();
      notifyListeners();
    }
  }

  // reloads the code box
  Future<void> reloadCodeBox() async {
    _codeBox = await Hive.openBox<CodeData>('codeData');
    _isReady = true;
    notifyListeners();
  }
}
