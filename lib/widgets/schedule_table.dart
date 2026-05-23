import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_model.dart';

class ScheduleTableView extends StatelessWidget {
  const ScheduleTableView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    return Column(
      children: [
        // Title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          width: double.infinity,
          child: Text(
            provider.tableTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              decoration: TextDecoration.underline,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
        // Table header
        Container(
          color: const Color(0xFF0D47A1),
          child: const Row(
            children: [
              _HeaderCell('التاريخ', flex: 2),
              _HeaderCell('اليوم', flex: 3),
              _HeaderCell('8ص - 2ظ', flex: 5),
              _HeaderCell('2ظ - 8م', flex: 5),
              _HeaderCell('8م - 8ص', flex: 5),
            ],
          ),
        ),
        // Table rows
        Expanded(
          child: ListView.builder(
            itemCount: provider.days.length,
            itemBuilder: (context, index) {
              final day = provider.days[index];
              return _DayRow(day: day, dayIndex: index);
            },
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final ShiftDay day;
  final int dayIndex;

  const _DayRow({required this.day, required this.dayIndex});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final isFriday = day.isFriday;
    final baseColor = isFriday ? const Color(0xFFF5F5F5) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: baseColor,
        border: const Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date
            _FixedCell(
              flex: 2,
              child: Text(
                '${day.day}',
                style: TextStyle(fontSize: 11, fontWeight: isFriday ? FontWeight.bold : FontWeight.normal),
                textAlign: TextAlign.center,
              ),
            ),
            // Day name
            _FixedCell(
              flex: 3,
              child: Text(
                day.dayName,
                style: TextStyle(fontSize: 11, fontWeight: isFriday ? FontWeight.bold : FontWeight.normal, color: isFriday ? Colors.red.shade700 : Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
            // Shifts
            _ShiftCell(day: day, shiftIndex: 0, dayIndex: dayIndex),
            _ShiftCell(day: day, shiftIndex: 1, dayIndex: dayIndex),
            _ShiftCell(day: day, shiftIndex: 2, dayIndex: dayIndex),
          ],
        ),
      ),
    );
  }
}

class _FixedCell extends StatelessWidget {
  final Widget child;
  final int flex;
  const _FixedCell({required this.child, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Color(0xFFCCCCCC))),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _ShiftCell extends StatelessWidget {
  final ShiftDay day;
  final int shiftIndex;
  final int dayIndex;

  const _ShiftCell({required this.day, required this.shiftIndex, required this.dayIndex});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final isSelected = provider.selectedDayIndex == dayIndex && provider.selectedShiftIndex == shiftIndex;
    final content = day.getShift(shiftIndex);
    final names = content.isEmpty ? <String>[] : content.split(' - ').where((n) => n.trim().isNotEmpty).toList();

    return Expanded(
      flex: 5,
      child: GestureDetector(
        onTap: () {
          if (provider.selectedWorkers.isNotEmpty) {
            provider.selectCell(dayIndex, shiftIndex);
          } else {
            provider.selectedDayIndex == dayIndex && provider.selectedShiftIndex == shiftIndex
                ? _showCellOptions(context, provider, names)
                : _showCellOptions(context, provider, names);
            provider.selectCell(dayIndex, shiftIndex);
          }
        },
        onLongPress: () => _showCellOptions(context, provider, names),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF9C4) : Colors.transparent,
            border: Border(
              right: const BorderSide(color: Color(0xFFCCCCCC)),
              left: isSelected ? const BorderSide(color: Color(0xFFFBC02D), width: 2) : BorderSide.none,
            ),
          ),
          child: names.isEmpty
              ? const SizedBox(height: 24)
              : Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  alignment: WrapAlignment.center,
                  children: names.map((name) => _NameChip(name: name, dayIndex: dayIndex, shiftIndex: shiftIndex)).toList(),
                ),
        ),
      ),
    );
  }

  void _showCellOptions(BuildContext context, ScheduleProvider provider, List<String> names) {
    if (names.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'يوم ${day.dayName} ${day.day} - ${["صباحي", "مسائي", "ليلي"][shiftIndex]}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...names.map((name) => ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF0D47A1)),
                title: Text(name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    provider.removeNameFromCell(dayIndex, shiftIndex, name);
                    Navigator.pop(context);
                  },
                ),
              )),
              ListTile(
                leading: const Icon(Icons.clear_all, color: Colors.red),
                title: const Text('مسح الخلية كاملة', style: TextStyle(color: Colors.red)),
                onTap: () {
                  provider.clearCell(dayIndex, shiftIndex);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameChip extends StatelessWidget {
  final String name;
  final int dayIndex;
  final int shiftIndex;

  const _NameChip({required this.name, required this.dayIndex, required this.shiftIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Text(name, style: const TextStyle(fontSize: 9, color: Color(0xFF1565C0))),
    );
  }
}
