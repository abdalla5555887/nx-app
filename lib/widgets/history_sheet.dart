import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_model.dart';

class HistorySheet extends StatelessWidget {
  const HistorySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Text('📚 النسخ المحفوظة محلياً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (provider.history.isEmpty)
              const Expanded(child: Center(child: Text('لا توجد نسخ محفوظة', style: TextStyle(color: Colors.grey))))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: provider.history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = provider.history[index];
                    return ListTile(
                      leading: const Icon(Icons.schedule, color: Color(0xFF0D47A1)),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(
                        '${provider.monthNames[item.month]} ${item.year}  •  ${_formatDate(item.savedAt)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                            onPressed: () => _rename(context, provider, index, item.name),
                            tooltip: 'تعديل الاسم',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () => _delete(context, provider, index),
                            tooltip: 'حذف',
                          ),
                        ],
                      ),
                      onTap: () => _restore(context, provider, item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _rename(BuildContext context, ScheduleProvider provider, int index, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل اسم النسخة'),
          content: TextField(controller: ctrl, textDirection: TextDirection.rtl),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (newName != null && newName.trim().isNotEmpty) {
      await provider.renameHistoryItem(index, newName.trim());
    }
  }

  Future<void> _delete(BuildContext context, ScheduleProvider provider, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف النسخة'),
          content: const Text('هل أنت متأكد من حذف هذه النسخة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) await provider.deleteHistoryItem(index);
  }

  void _restore(BuildContext context, ScheduleProvider provider, HistoryItem item) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('استعادة النسخة'),
          content: Text('هل تريد استعادة النسخة "${item.name}"؟\nسيتم استبدال الجدول الحالي.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                provider.loadHistoryItem(item);
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ تم الاستعادة بنجاح'), backgroundColor: Colors.green),
                );
              },
              child: const Text('استعادة'),
            ),
          ],
        ),
      ),
    );
  }
}
