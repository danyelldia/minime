import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/bill_item.dart';
import '../models/note_task.dart';
import '../providers/bill_provider.dart';
import '../providers/note_task_provider.dart';
import 'bill_edit_screen.dart';
import 'note_edit_screen.dart';

/// Month calendar showing every day that has a task or a bill due.
/// Tap a day to see its agenda below the calendar; tap an item to open
/// it for editing. This is a local, read-from-the-existing-data view -
/// no external account or sync involved (that's a separate step).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  List<NoteTask> _tasksOn(DateTime day, List<NoteTask> tasks) {
    final key = _dayKey(day);
    return tasks
        .where((t) => t.dueDate != null && _dayKey(t.dueDate!) == key)
        .toList();
  }

  List<BillItem> _billsOn(DateTime day, List<BillItem> bills) {
    final key = _dayKey(day);
    return bills
        .where((b) => b.dueDate != null && _dayKey(b.dueDate!) == key)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<NoteTaskProvider>().tasks;
    final bills = context.watch<BillProvider>().items;

    final dayTasks = _tasksOn(_selectedDay, tasks);
    final dayBills = _billsOn(_selectedDay, bills);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar<Object>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) => _focusedDay = focused,
            eventLoader: (day) => [
              ..._tasksOn(day, tasks),
              ..._billsOn(day, bills),
            ],
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(color: primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                color: primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(color: primary, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false),
          ),
          const Divider(height: 1),
          Expanded(
            child: (dayTasks.isEmpty && dayBills.isEmpty)
                ? const Center(child: Text('Nimic in ziua asta'))
                : ListView(
                    children: [
                      ...dayTasks.map((t) => ListTile(
                            leading: Icon(
                              t.isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
                            ),
                            title: Text(t.title),
                            subtitle: (t.description != null && t.description!.isNotEmpty)
                                ? Text(t.description!)
                                : null,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => NoteEditScreen(existing: t)),
                            ),
                          )),
                      ...dayBills.map((b) => ListTile(
                            leading: Icon(
                              b.isSettled ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                            ),
                            title: Text(b.name),
                            subtitle: Text('${b.amount.toStringAsFixed(2)} lei'),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => BillEditScreen(existing: b)),
                            ),
                          )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
