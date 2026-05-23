import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_model.dart';

class StatsSheet extends StatelessWidget {
  const StatsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final stats = provider.calculateStats();
    final sortedNames = stats.keys.toList()..sort();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Text(
              'تقرير الشيفتات والساعات الشهرية',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.underline),
            ),
            const SizedBox(height: 8),
            const Text('* شيفت السهر (ليلاً) يُحسب بـ 2 شيفت (12 ساعة)', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            if (sortedNames.isEmpty)
              const Expanded(child: Center(child: Text('لا توجد بيانات. أملأ الجدول أولاً.', style: TextStyle(color: Colors.grey))))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2),
                      4: FlexColumnWidth(2),
                    },
                    children: [
                      // Header
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFF0D47A1)),
                        children: [
                          _headerCell('الاسم'),
                          _headerCell('صباحي/مسائي'),
                          _headerCell('ليلي (×2)'),
                          _headerCell('إجمالي شيفتات'),
                          _headerCell('إجمالي ساعات'),
                        ],
                      ),
                      // Rows
                      ...sortedNames.asMap().entries.map((entry) {
                        final i = entry.key;
                        final name = entry.value;
                        final s = stats[name]!;
                        return TableRow(
                          decoration: BoxDecoration(color: i.isEven ? Colors.white : const Color(0xFFF5F5F5)),
                          children: [
                            _dataCell(name, textAlign: TextAlign.right),
                            _dataCell('${s.normalShifts}'),
                            _dataCell('${s.nightShifts} (=${s.nightShifts * 2})'),
                            _dataCell('${s.totalShifts}', color: Colors.green.shade800, bg: Colors.green.shade50),
                            _dataCell('${s.totalHours}h', color: Colors.red.shade800, bg: Colors.red.shade50),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text) => Padding(
    padding: const EdgeInsets.all(6),
    child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
  );

  Widget _dataCell(String text, {TextAlign textAlign = TextAlign.center, Color? color, Color? bg}) => Container(
    color: bg,
    padding: const EdgeInsets.all(6),
    child: Text(text, textAlign: textAlign, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
  );
}
