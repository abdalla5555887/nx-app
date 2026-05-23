import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';

class ScheduleProvider extends ChangeNotifier {
  // Default workers
  List<String> workers = [
    "خالد قاسم", "نرمين طارق", "جيهان نصر", "بسمة محمد",
    "الاء عبد النبي", "الاء قاسم", "مها والي", "عبد الله احمد",
    "اسماعيل العماوي", "احمد محمود", "حسام حسن", "وفاء النمر", "احمد الحسيني"
  ];

  List<String> selectedWorkers = [];
  List<ShiftDay> days = [];
  List<HistoryItem> history = [];

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  // Selected cell for manual edits
  int? selectedDayIndex;
  int? selectedShiftIndex;

  static const _workersKey = 'nabatchy_worker_list';
  static const _historyKey = 'nabatchy_v5_history';

  final List<String> arabicDays = [
    'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'
  ];

  final List<String> monthNames = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  Future<void> init() async {
    await _loadWorkers();
    await _loadHistory();
    generateTable();
  }

  Future<void> _loadWorkers() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_workersKey);
    if (saved != null && saved.isNotEmpty) workers = saved;
  }

  Future<void> _saveWorkers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_workersKey, workers);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      history = list.map((e) => HistoryItem.fromJson(e)).toList();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(history.map((h) => h.toJson()).toList()));
  }

  void generateTable() {
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    final newDays = <ShiftDay>[];
    for (int d = 1; d <= daysInMonth; d++) {
      final dateObj = DateTime(selectedYear, selectedMonth, d);
      newDays.add(ShiftDay(
        day: d,
        dayName: arabicDays[dateObj.weekday % 7],
      ));
    }
    // Preserve existing data if same month/year
    if (days.isNotEmpty && days.length == newDays.length) {
      for (int i = 0; i < days.length; i++) {
        newDays[i].morning = days[i].morning;
        newDays[i].afternoon = days[i].afternoon;
        newDays[i].night = days[i].night;
      }
    }
    days = newDays;
    selectedDayIndex = null;
    selectedShiftIndex = null;
    notifyListeners();
  }

  void setMonth(int month) {
    selectedMonth = month;
    days = []; // clear so it regenerates fresh
    generateTable();
  }

  void setYear(int year) {
    selectedYear = year;
    days = [];
    generateTable();
  }

  void selectCell(int dayIdx, int shiftIdx) {
    if (selectedWorkers.isEmpty) {
      // Just select cell for manual editing
      selectedDayIndex = dayIdx;
      selectedShiftIndex = shiftIdx;
      notifyListeners();
      return;
    }

    // Assign selected workers to cell
    for (final name in selectedWorkers) {
      days[dayIdx].addNameToShift(shiftIdx, name);
    }
    selectedDayIndex = dayIdx;
    selectedShiftIndex = shiftIdx;
    notifyListeners();
  }

  void toggleWorker(String name) {
    if (selectedWorkers.contains(name)) {
      selectedWorkers.remove(name);
    } else {
      selectedWorkers.add(name);
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedWorkers = [];
    notifyListeners();
  }

  void addWorker(String name) {
    name = name.trim();
    if (name.isNotEmpty && !workers.contains(name)) {
      workers.add(name);
      _saveWorkers();
      notifyListeners();
    }
  }

  void deleteWorkers(List<String> toDelete) {
    workers.removeWhere((w) => toDelete.contains(w));
    selectedWorkers.removeWhere((w) => toDelete.contains(w));
    _saveWorkers();
    notifyListeners();
  }

  void removeNameFromCell(int dayIdx, int shiftIdx, String name) {
    days[dayIdx].removeNameFromShift(shiftIdx, name);
    notifyListeners();
  }

  void clearCell(int dayIdx, int shiftIdx) {
    days[dayIdx].setShift(shiftIdx, '');
    notifyListeners();
  }

  void addManualName(int dayIdx, int shiftIdx, String name) {
    name = name.trim();
    if (name.isNotEmpty) {
      days[dayIdx].addNameToShift(shiftIdx, name);
      notifyListeners();
    }
  }

  void applyBulk({
    required List<String> selectedDays,
    required List<int> selectedShifts,
  }) {
    if (selectedWorkers.isEmpty || selectedDays.isEmpty || selectedShifts.isEmpty) return;
    for (final day in days) {
      if (selectedDays.contains(day.dayName)) {
        for (final shift in selectedShifts) {
          for (final name in selectedWorkers) {
            day.addNameToShift(shift, name);
          }
        }
      }
    }
    notifyListeners();
  }

  Future<void> saveToHistory(String name) async {
    final item = HistoryItem(
      name: name,
      savedAt: DateTime.now(),
      month: selectedMonth,
      year: selectedYear,
      days: days.map((d) => ShiftDay(
        day: d.day,
        dayName: d.dayName,
        morning: d.morning,
        afternoon: d.afternoon,
        night: d.night,
      )).toList(),
    );
    history.insert(0, item);
    if (history.length > 15) history.removeLast();
    await _saveHistory();
    notifyListeners();
  }

  void loadHistoryItem(HistoryItem item) {
    selectedMonth = item.month;
    selectedYear = item.year;
    days = item.days.map((d) => ShiftDay(
      day: d.day,
      dayName: d.dayName,
      morning: d.morning,
      afternoon: d.afternoon,
      night: d.night,
    )).toList();
    notifyListeners();
  }

  Future<void> deleteHistoryItem(int index) async {
    history.removeAt(index);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> renameHistoryItem(int index, String newName) async {
    history[index] = HistoryItem(
      name: newName,
      savedAt: history[index].savedAt,
      month: history[index].month,
      year: history[index].year,
      days: history[index].days,
    );
    await _saveHistory();
    notifyListeners();
  }

  Map<String, WorkerStats> calculateStats() {
    final stats = <String, WorkerStats>{};
    for (final day in days) {
      void processCell(String cell, String type) {
        if (cell.trim().isEmpty) return;
        final names = cell.split(' - ').map((n) => n.trim()).where((n) => n.isNotEmpty);
        for (final name in names) {
          stats.putIfAbsent(name, () => WorkerStats(name: name));
          if (type == 'night') {
            stats[name]!.nightShifts++;
          } else {
            stats[name]!.normalShifts++;
          }
        }
      }
      processCell(day.morning, 'normal');
      processCell(day.afternoon, 'normal');
      processCell(day.night, 'night');
    }
    return stats;
  }

  String get tableTitle =>
      'جدول الكيميائيين والفنيين ببنك الدم عن شهر ${monthNames[selectedMonth]} $selectedYear';

  String exportToJson() {
    return jsonEncode({
      'month': selectedMonth,
      'year': selectedYear,
      'workers': workers,
      'data': days.map((d) => [d.morning, d.afternoon, d.night]).toList(),
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  void importFromJson(String raw) {
    final backup = jsonDecode(raw) as Map<String, dynamic>;
    if (backup['month'] != null) selectedMonth = backup['month'];
    if (backup['year'] != null) selectedYear = backup['year'];
    if (backup['workers'] != null) {
      workers = List<String>.from(backup['workers']);
      _saveWorkers();
    }
    generateTable();
    final data = backup['data'] as List?;
    if (data != null) {
      for (int i = 0; i < data.length && i < days.length; i++) {
        final row = data[i] as List;
        days[i].morning = row[0] ?? '';
        days[i].afternoon = row[1] ?? '';
        days[i].night = row[2] ?? '';
      }
    }
    notifyListeners();
  }
}
