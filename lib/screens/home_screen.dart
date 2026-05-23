import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/schedule_table.dart';
import '../widgets/controls_panel.dart';
import '../widgets/stats_sheet.dart';
import '../widgets/history_sheet.dart';
import '../widgets/month_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text('Nabatchy Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'الإحصائيات',
            onPressed: () => _showStats(context),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'السجل',
            onPressed: () => _showHistory(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenu(context, value, provider),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'save', child: Row(children: [Icon(Icons.save, color: Colors.green), SizedBox(width: 8), Text('حفظ بالتطبيق')])),
              const PopupMenuItem(value: 'export', child: Row(children: [Icon(Icons.download, color: Colors.orange), SizedBox(width: 8), Text('تصدير ملف')])),
              const PopupMenuItem(value: 'import', child: Row(children: [Icon(Icons.upload, color: Colors.purple), SizedBox(width: 8), Text('استعادة ملف')])),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.table_chart), text: 'الجدول'),
            Tab(icon: Icon(Icons.manage_accounts), text: 'التحكم'),
          ],
        ),
      ),
      body: Column(
        children: [
          const MonthSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ScheduleTableView(),
                ControlsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStats(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ScheduleProvider>(),
        child: const StatsSheet(),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ScheduleProvider>(),
        child: const HistorySheet(),
      ),
    );
  }

  Future<void> _handleMenu(BuildContext context, String value, ScheduleProvider provider) async {
    if (value == 'save') {
      final controller = TextEditingController(
        text: '${provider.monthNames[provider.selectedMonth]} ${provider.selectedYear}',
      );
      final name = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('حفظ النسخة', textDirection: TextDirection.rtl),
          content: TextField(
            controller: controller,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(labelText: 'اسم النسخة'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('حفظ'),
            ),
          ],
        ),
      );
      if (name != null && name.isNotEmpty) {
        await provider.saveToHistory(name);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم الحفظ بنجاح'), backgroundColor: Colors.green),
          );
        }
      }
    } else if (value == 'export') {
      final json = provider.exportToJson();
      // In a real app, use share_plus or path_provider to save file
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📥 جاري تصدير الملف...'), backgroundColor: Colors.orange),
      );
    } else if (value == 'import') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📤 جاري استعادة الملف...'), backgroundColor: Colors.purple),
      );
    }
  }
}
