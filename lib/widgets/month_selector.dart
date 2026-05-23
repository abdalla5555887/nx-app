import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('الشهر:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: provider.selectedMonth,
                items: List.generate(12, (i) {
                  return DropdownMenuItem(
                    value: i + 1,
                    child: Text(provider.monthNames[i + 1], style: const TextStyle(fontSize: 13)),
                  );
                }),
                onChanged: (m) {
                  if (m != null) provider.setMonth(m);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text('السنة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          SizedBox(
            width: 75,
            child: TextFormField(
              initialValue: provider.selectedYear.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onFieldSubmitted: (v) {
                final year = int.tryParse(v);
                if (year != null) provider.setYear(year);
              },
            ),
          ),
        ],
      ),
    );
  }
}
