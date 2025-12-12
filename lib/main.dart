import 'package:flutter/material.dart';
import 'package:taskeventmanager/Screens/addtask.dart';
import 'package:taskeventmanager/Screens/addevent.dart';
import 'package:taskeventmanager/models/event.dart';
import 'package:taskeventmanager/models/task.dart';
import 'package:taskeventmanager/data/db_helper.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task & Event Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _db = DBHelper();

  List<Task> _tasks = [];
  List<EventItem> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      _tasks = await _db.getAllTasks();
      _events = await _db.getAllEvents();
      setState(() {});
    } catch (e) {
      debugPrint("DB Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _onFabPressed() async {
    if (_selectedIndex == 0) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddTaskScreen()),
      );

      if (result != null && result is Map<String, dynamic>) {
        final title = result['title'] ?? '';
        final desc = result['description'] ?? '';

        if (title.toString().trim().isNotEmpty) {
          await _db.insertTask(
            Task(title: title, description: desc, isDone: 0),
          );
          await _loadAll();
        }
      }
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddEventScreen()),
      );

      if (result != null && result is Map<String, dynamic>) {
        final title = result['title'] ?? '';
        final date = result['date'] ?? '';
        final time = result['time'] ?? '';

        if (title.toString().trim().isNotEmpty) {
          await _db.insertEvent(
            EventItem(title: title, date: date, time: time),
          );
          await _loadAll();
        }
      }
    }
  }

  // TASKS PAGE
  Widget _tasksPage(double bottomPadding) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      child:
          _tasks.isEmpty
              ? const Center(
                child: Text(
                  'No tasks yet. Tap + to add one.',
                  style: TextStyle(color: Colors.black54),
                ),
              )
              : ListView.separated(
                itemCount: _tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final task = _tasks[i];
                  final done = task.isDone == 1;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        value: done,
                        onChanged: (val) async {
                          final updated = Task(
                            id: task.id,
                            title: task.title,
                            description: task.description,
                            isDone: val == true ? 1 : 0,
                          );
                          await _db.updateTask(updated);
                          await _loadAll();
                        },
                      ),
                      title: Text(task.title),
                      subtitle: Text(
                        task.description?.isEmpty ?? true
                            ? "Tap to edit"
                            : task.description!,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (task.id != null) {
                            await _db.deleteTask(task.id!);
                            await _loadAll();
                          }
                        },
                      ),
                      onTap: () async {
                        final edited = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTaskScreen(existingTask: task),
                          ),
                        );

                        if (edited != null && edited is Map<String, dynamic>) {
                          final updated = Task(
                            id: edited['id'] ?? task.id,
                            title: edited['title'],
                            description: edited['description'],
                            isDone: task.isDone,
                          );
                          await _db.updateTask(updated);
                          await _loadAll();
                        }
                      },
                    ),
                  );
                },
              ),
    );
  }

  // EVENTS PAGE (with edit support)
  Widget _eventsPage(double bottomPadding) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      child:
          _events.isEmpty
              ? const Center(
                child: Text(
                  'No events yet. Tap + to add one.',
                  style: TextStyle(color: Colors.black54),
                ),
              )
              : ListView.separated(
                itemCount: _events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final event = _events[i];

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.event, color: Colors.black54),
                      title: Text(event.title),
                      subtitle: Text('${event.date} • ${event.time}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (event.id != null) {
                            await _db.deleteEvent(event.id!);
                            await _loadAll();
                          }
                        },
                      ),
                      onTap: () async {
                        // Edit event flow
                        final edited = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AddEventScreen(existingEvent: event),
                          ),
                        );

                        if (edited != null && edited is Map<String, dynamic>) {
                          // parse id safely
                          final dynamic rawId = edited['id'];
                          final int? id =
                              rawId != null
                                  ? int.tryParse(rawId.toString()) ?? event.id
                                  : event.id;
                          final String title =
                              (edited['title'] ?? '').toString().trim();
                          final String date =
                              (edited['date'] ?? '').toString().trim();
                          final String time =
                              (edited['time'] ?? '').toString().trim();

                          if (title.isNotEmpty) {
                            final updated = EventItem(
                              id: id,
                              title: title,
                              date: date,
                              time: time,
                            );
                            await _db.updateEvent(updated);
                            await _loadAll();
                          }
                        }
                      },
                    ),
                  );
                },
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 70;

    final pages = [_tasksPage(bottomPadding), _eventsPage(bottomPadding)];

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A86FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔥 CLEAN TITLE ONLY — menu/settings removed
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Center(
                  child: Text(
                    "Task & Event Manager",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IndexedStack(index: _selectedIndex, children: pages),
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onFabPressed,
        label: Text(_selectedIndex == 0 ? "Add Task" : "Add Event"),
        icon: Icon(_selectedIndex == 0 ? Icons.add_task : Icons.event),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.checklist,
                        color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tasks",
                        style: TextStyle(
                          color:
                              _selectedIndex == 0 ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Events",
                        style: TextStyle(
                          color:
                              _selectedIndex == 1 ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
