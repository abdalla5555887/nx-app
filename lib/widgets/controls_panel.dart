import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';

class ControlsPanel extends StatefulWidget {
  const ControlsPanel({super.key});

  @override
  State<ControlsPanel> createState() => _ControlsPanelState();
}

class _ControlsPanelState extends State<ControlsPanel> {
  final _newWorkerCtrl = TextEditingController();
  final _manualCtrl = TextEditingController();

  final List<String> _weekDays = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
  final Set<String> _bulkDays = {};
  final Set<int> _bulkShifts = {};

  @override
  void dispose() {
    _newWorkerCtrl.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Selected workers display
          _buildSectionCard(
            title: 'الأسماء المختارة حالياً',
            titleColor: Colors.red.shade700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                provider.selectedWorkers.isEmpty
                    ? const Text('لا يوجد', style: TextStyle(color: Colors.grey, fontSize: 13))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: provider.selectedWorkers.map((name) => Chip(
                          label: Text(name, style: const TextStyle(fontSize: 12)),
                          backgroundColor: const Color(0xFF0D47A1),
                          labelStyle: const TextStyle(color: Colors.white),
                          deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
                          onDeleted: () => provider.toggleWorker(name),
                        )).toList(),
                      ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: provider.clearSelection,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('إلغاء تحديد الكل', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Workers palette
          _buildSectionCard(
            title: 'قائمة الموظفين — اضغط لتحديد',
            titleColor: const Color(0xFF0D47A1),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: provider.workers.map((name) {
                final isSelected = provider.selectedWorkers.contains(name);
                return GestureDetector(
                  onTap: () => provider.toggleWorker(name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
                      border: Border.all(color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4)] : null,
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Add / Delete worker
          _buildSectionCard(
            title: 'إدارة الموظفين',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newWorkerCtrl,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'اكتب الاسم هنا...',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.addWorker(_newWorkerCtrl.text);
                        _newWorkerCtrl.clear();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('حفظ', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                if (provider.selectedWorkers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmDelete(context, provider),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('حذف الأسماء المختارة نهائياً', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bulk assignment
          _buildSectionCard(
            title: '⚡ إضافة سريعة للمجموعة',
            titleColor: const Color(0xFF0D47A1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر الأيام:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _weekDays.map((day) {
                    final selected = _bulkDays.contains(day);
                    return FilterChip(
                      label: Text(day, style: const TextStyle(fontSize: 11)),
                      selected: selected,
                      selectedColor: const Color(0xFFBBDEFB),
                      onSelected: (v) => setState(() => v ? _bulkDays.add(day) : _bulkDays.remove(day)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                const Text('اختر الفترة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _ShiftChip(label: 'صباحاً', index: 0, selectedShifts: _bulkShifts, onToggle: () => setState(() => _bulkShifts.contains(0) ? _bulkShifts.remove(0) : _bulkShifts.add(0))),
                    const SizedBox(width: 6),
                    _ShiftChip(label: 'مساءً', index: 1, selectedShifts: _bulkShifts, onToggle: () => setState(() => _bulkShifts.contains(1) ? _bulkShifts.remove(1) : _bulkShifts.add(1))),
                    const SizedBox(width: 6),
                    _ShiftChip(label: 'ليلاً', index: 2, selectedShifts: _bulkShifts, onToggle: () => setState(() => _bulkShifts.contains(2) ? _bulkShifts.remove(2) : _bulkShifts.add(2))),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.applyBulk(
                        selectedDays: _bulkDays.toList(),
                        selectedShifts: _bulkShifts.toList(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ تم التطبيق بنجاح'), backgroundColor: Colors.green),
                      );
                    },
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: const Text('تطبيق الإضافة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Manual input for selected cell
          _buildSectionCard(
            title: 'إضافة يدوية للخلية المحددة',
            child: Column(
              children: [
                Builder(builder: (ctx) {
                  final p = ctx.watch<ScheduleProvider>();
                  final hasCell = p.selectedDayIndex != null;
                  return Text(
                    hasCell
                        ? 'الخلية المحددة: يوم ${p.days[p.selectedDayIndex!].dayName} ${p.days[p.selectedDayIndex!].day} - ${["صباحي", "مسائي", "ليلي"][p.selectedShiftIndex ?? 0]}'
                        : 'لم تختر خلية بعد — اضغط على خلية من الجدول',
                    style: TextStyle(fontSize: 12, color: hasCell ? Colors.green.shade700 : Colors.grey),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualCtrl,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'اسم إضافي يدوي...',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () {
                        final p = context.read<ScheduleProvider>();
                        if (p.selectedDayIndex != null && p.selectedShiftIndex != null) {
                          p.addManualName(p.selectedDayIndex!, p.selectedShiftIndex!, _manualCtrl.text);
                          _manualCtrl.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('اختر خلية أولاً من تاب الجدول')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('إضافة', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () {
                        final p = context.read<ScheduleProvider>();
                        if (p.selectedDayIndex != null && p.selectedShiftIndex != null) {
                          p.clearCell(p.selectedDayIndex!, p.selectedShiftIndex!);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      child: const Text('مسح', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, Color? titleColor, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: titleColor ?? Colors.black87)),
          const Divider(height: 12),
          child,
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ScheduleProvider provider) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف الأسماء المختارة (${provider.selectedWorkers.join("، ")}؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                provider.deleteWorkers(List.from(provider.selectedWorkers));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  final String label;
  final int index;
  final Set<int> selectedShifts;
  final VoidCallback onToggle;

  const _ShiftChip({required this.label, required this.index, required this.selectedShifts, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final selected = selectedShifts.contains(index);
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0D47A1) : Colors.white,
          border: Border.all(color: selected ? const Color(0xFF0D47A1) : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.black87)),
      ),
    );
  }
}
