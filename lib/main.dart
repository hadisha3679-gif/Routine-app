import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RoutineApp());
}

const Color forest = Color(0xFF287D62);
const Color mint = Color(0xFFE5F4EC);
const Color orange = Color(0xFFF4A261);
const Color ink = Color(0xFF26332D);
const Color canvas = Color(0xFFF7F8F4);

class RoutineApp extends StatelessWidget {
  const RoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'روتین',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(seedColor: forest),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: RoutineHome(),
      ),
    );
  }
}

class TaskItem {
  TaskItem({
    required this.title,
    this.time = '',
    this.done = false,
    this.priority = 'معمولی',
  });
  String title;
  String time;
  bool done;
  String priority;

  Map<String, dynamic> toJson() => {
    'title': title, 'time': time, 'done': done, 'priority': priority,
  };
  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    title: json['title'] ?? '',
    time: json['time'] ?? '',
    done: json['done'] ?? false,
    priority: json['priority'] ?? 'معمولی',);
}

class CustomerItem {
  CustomerItem({required this.name, this.contact = '', this.followUp = '', this.note = ''});
  String name;
  String contact;
  String followUp;
  String note;
  Map<String, dynamic> toJson() => {
    'name': name, 'contact': contact, 'followUp': followUp, 'note': note,
  };
  factory CustomerItem.fromJson(Map<String, dynamic> json) => CustomerItem(
    name: json['name'] ?? '',
    contact: json['contact'] ?? '',
    followUp: json['followUp'] ?? '',
    note: json['note'] ?? '',
  );
}

class RoutineHome extends StatefulWidget {
  const RoutineHome({super.key});
  @override
  State<RoutineHome> createState() => _RoutineHomeState();
}

class _RoutineHomeState extends State<RoutineHome> {
  int _tab = 0;
  bool _loaded = false;
  final List<TaskItem> _tasks = [];
  final List<CustomerItem> _customers = [];
  final List<String> _workouts = [];
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _workoutController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final taskRaw = prefs.getString('tasks');
    final customerRaw = prefs.getString('customers');
    final workoutRaw = prefs.getStringList('workouts');
    if (!mounted) return;
    setState(() {
      if (taskRaw != null) {
        _tasks.addAll((jsonDecode(taskRaw) as List).map((e) => TaskItem.fromJson(e)));
      } else {
        _tasks.addAll([
          TaskItem(title: 'برنامه‌ریزی امروز', time: 'صبح', priority: 'مهم'),
          TaskItem(title: 'بررسی پیام‌های مشتریان', time: '۱۱:۰۰'),
          TaskItem(title: 'آماده شدن برای باشگاه', time: '۱۸:۰۰'),
        ]);
      }
      if (customerRaw != null) {
        _customers.addAll((jsonDecode(customerRaw) as List).map((e) => CustomerItem.fromJson(e)));
      }
      if (workoutRaw != null) _workouts.addAll(workoutRaw);
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks', jsonEncode(_tasks.map((e) => e.toJson()).toList()));
    await prefs.setString('customers', jsonEncode(_customers.map((e) => e.toJson()).toList()));
    await prefs.setStringList('workouts', _workouts);
  }

  @override
  void dispose() {
    _taskController.dispose();
    _customerController.dispose();
    _workoutController.dispose();
    super.dispose();
  }

  String get _today {
    final j = Jalali.now();
    final f = j.formatter;
    return '${f.d} ${f.mN} ${f.yyyy}';
  }

  int get _completed => _tasks.where((t) => t.done).length;
  double get _progress => _tasks.isEmpty ? 0 : _completed / _tasks.length;

  void _addTask() {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;
    setState(() => _tasks.add(TaskItem(title: title)));
    _taskController.clear();
    _save();
    Navigator.pop(context);
  }

  void _addCustomer() {
    final name = _customerController.text.trim();
    if (name.isEmpty) return;
    setState(() => _customers.add(CustomerItem(name: name)));
    _customerController.clear();
    _save();
    Navigator.pop(context);
  }

  void _addWorkout() {
    final title = _workoutController.text.trim();
    if (title.isEmpty) return;
    setState(() => _workouts.add(title));
    _workoutController.clear();
    _save();
    Navigator.pop(context);
  }

  void _showAddDialog({required String title, required TextEditingController controller, required VoidCallback onSave, String hint = 'عنوان'}) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (_) => onSave(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          FilledButton(onPressed: onSave, child: const Text('ذخیره')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pages = [
      _homePage(),
      _tasksPage(),
      _customersPage(),
      _gymPage(),
      _settingsPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.spa_rounded, color: forest, size: 28),
            SizedBox(width: 8),
            Text('روتین', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'پیام روز',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('قدم‌های کوچک، تغییرهای بزرگ می‌سازند 🌱')),
            ),
            icon: const Icon(Icons.wb_sunny_outlined),
          ),
        ],
      ),
      body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: pages[_tab])),
      floatingActionButton: _tab == 1 || _tab == 2 || _tab == 3
          ? FloatingActionButton.extended(
              onPressed: () {
                if (_tab == 1) _showAddDialog(title: 'کار جدید', controller: _taskController, onSave: _addTask, hint: 'مثلاً تماس با مشتری');
                if (_tab == 2) _showAddDialog(title: 'مشتری جدید', controller: _customerController, onSave: _addCustomer, hint: 'نام مشتری');
                if (_tab == 3) _showAddDialog(title: 'برنامه تمرین', controller: _workoutController, onSave: _addWorkout, hint: 'مثلاً تمرین پایین‌تنه');
              },
              icon: const Icon(Icons.add),
              label: const Text('افزودن'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: 'کارها'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'مشتریان'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'باشگاه'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'تنظیمات'),
        ],
      ),
    );
  }

  Widget _homePage() {
    final todayTasks = _tasks.take(4).toList();
    return ListView(
      key: const ValueKey('home'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFE4F3E9), Color(0xFFF4F7E9)], begin: Alignment.topRight, end: Alignment.bottomLeft),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('امروز $_today', style: const TextStyle(color: forest, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text('آرام پیش برو، اما ادامه بده.', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 8),
              const Text('هر قدم کوچک، تو را به هدفت نزدیک‌تر می‌کند.', style: TextStyle(color: Color(0xFF58685E))),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(value: _progress, minHeight: 9, backgroundColor: Colors.white, color: forest),
                )),
                const SizedBox(width: 12),
                Text('${(_progress * 100).round()}٪', style: const TextStyle(fontWeight: FontWeight.bold, color: forest)),
              ]),
              const SizedBox(height: 5),
              Text('$_completed از ${_tasks.length} کار انجام شده', style: const TextStyle(fontSize: 12, color: Color(0xFF58685E))),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _statCard(Icons.task_alt, 'کارهای باقی‌مانده', '${_tasks.length - _completed}', const Color(0xFFE6F2EA))),
          const SizedBox(width: 12),
          Expanded(child: _statCard(Icons.people_alt_outlined, 'مشتریان', '${_customers.length}', const Color(0xFFFFF0DF))),
        ]),
        const SizedBox(height: 22),
        _sectionTitle('برنامه پیش رو', 'مشاهده همه', () => setState(() => _tab = 1)),
        const SizedBox(height: 8),
        if (todayTasks.isEmpty)
          _emptyCard('فعلاً کاری ثبت نشده؛ یک قدم کوچک اضافه کن.')
        else
          ...todayTasks.map(_taskTile),
        const SizedBox(height: 20),
        _sectionTitle('یادآوری دوستانه', '', null),
        Container(
          padding: const EdgeInsets.all(17),
