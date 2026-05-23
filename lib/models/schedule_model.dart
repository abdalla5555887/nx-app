class ShiftDay {
  final int day;
  final String dayName;
  String morning; // 8 ص - 2 ظ
  String afternoon; // 2 ظ - 8 م
  String night; // 8 م - 8 ص

  ShiftDay({
    required this.day,
    required this.dayName,
    this.morning = '',
    this.afternoon = '',
    this.night = '',
  });

  bool get isFriday => dayName == 'الجمعة';

  List<String> getMorningNames() => _parseNames(morning);
  List<String> getAfternoonNames() => _parseNames(afternoon);
  List<String> getNightNames() => _parseNames(night);

  List<String> _parseNames(String val) =>
      val.isEmpty ? [] : val.split(' - ').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  String getShift(int index) {
    if (index == 0) return morning;
    if (index == 1) return afternoon;
    return night;
  }

  void setShift(int index, String value) {
    if (index == 0) morning = value;
    else if (index == 1) afternoon = value;
    else night = value;
  }

  void addNameToShift(int index, String name) {
    final existing = _parseNames(getShift(index));
    if (!existing.contains(name)) {
      existing.add(name);
      setShift(index, existing.join(' - '));
    }
  }

  void removeNameFromShift(int index, String name) {
    final existing = _parseNames(getShift(index));
    existing.remove(name);
    setShift(index, existing.join(' - '));
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'dayName': dayName,
    'morning': morning,
    'afternoon': afternoon,
    'night': night,
  };

  factory ShiftDay.fromJson(Map<String, dynamic> json) => ShiftDay(
    day: json['day'],
    dayName: json['dayName'],
    morning: json['morning'] ?? '',
    afternoon: json['afternoon'] ?? '',
    night: json['night'] ?? '',
  );
}

class HistoryItem {
  final String name;
  final DateTime savedAt;
  final int month;
  final int year;
  final List<ShiftDay> days;

  HistoryItem({
    required this.name,
    required this.savedAt,
    required this.month,
    required this.year,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'savedAt': savedAt.toIso8601String(),
    'month': month,
    'year': year,
    'days': days.map((d) => d.toJson()).toList(),
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    name: json['name'],
    savedAt: DateTime.parse(json['savedAt']),
    month: json['month'],
    year: json['year'],
    days: (json['days'] as List).map((d) => ShiftDay.fromJson(d)).toList(),
  );
}

class WorkerStats {
  final String name;
  int normalShifts;
  int nightShifts;

  WorkerStats({required this.name, this.normalShifts = 0, this.nightShifts = 0});

  int get totalShifts => normalShifts + (nightShifts * 2);
  int get totalHours => (normalShifts * 6) + (nightShifts * 12);
}
