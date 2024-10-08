import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AnnouncementProvider extends ChangeNotifier {
  Set<String> _markedAnnouncements = {};
  List<dynamic> _markedAnnouncementsData = [];
  bool _showAllAnnouncements = false;

  Set<String> get markedAnnouncements => _markedAnnouncements;
  List<dynamic> get markedAnnouncementsData => _markedAnnouncementsData;
  bool get showAllAnnouncements => _showAllAnnouncements;

  AnnouncementProvider() {
    _loadMarkedAnnouncements();
  }

  Future<void> _loadMarkedAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    _markedAnnouncements =
        (prefs.getStringList('markedAnnouncements') ?? []).toSet();
    _markedAnnouncementsData = prefs
            .getStringList('markedAnnouncementsData')
            ?.map((e) => json.decode(e))
            .toList() ??
        [];
    notifyListeners();
  }

  Future<void> _saveMarkedAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'markedAnnouncements', _markedAnnouncements.toList());
    await prefs.setStringList('markedAnnouncementsData',
        _markedAnnouncementsData.map((e) => json.encode(e)).toList());
  }

  void addMarkedAnnouncement(String annId, dynamic data) {
    _markedAnnouncements.add(annId);
    _markedAnnouncementsData.add(data);
    _saveMarkedAnnouncements();
    notifyListeners();
  }

  void removeMarkedAnnouncement(String annId) {
    _markedAnnouncements.remove(annId);
    _markedAnnouncementsData.removeWhere((element) {
      return element['id'].toString() == annId;
    });
    _saveMarkedAnnouncements();
    notifyListeners();
  }

  void clearAllMarkedAnnouncements() {
    _markedAnnouncements.clear();
    _markedAnnouncementsData.clear();
    _saveMarkedAnnouncements();
    notifyListeners();
  }

  void toggleShowAllAnnouncements() {
    _showAllAnnouncements = !_showAllAnnouncements;
    notifyListeners();
  }
}
