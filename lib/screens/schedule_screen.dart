import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_colors.dart';
import '../utils/app_text.dart';

import 'live_events_screen.dart';
import 'add_user_screen.dart';
import 'manage_users_screen.dart';
import 'schedule_event_details_screen.dart';
import 'add_schedule_screen.dart'; // ⭐ NEW
import 'schedule_extra/user_selector_sheet.dart';
import 'schedule_extra/event_card.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Box usersBox;
  late Box scheduleBox;

  @override
  void initState() {
    super.initState();
    usersBox = Hive.box('users');
    scheduleBox = Hive.box('schedule');

    if (usersBox.isEmpty) {
      usersBox.put('main', {"name": "Me", "avatar": Icons.person.codePoint});
      usersBox.put('selectedUserKeys', ['main']);
    }

    if (!usersBox.containsKey('selectedUserKeys')) {
      usersBox.put('selectedUserKeys', ['main']);
    }
  }

  DateTime parseEventDate(Map event) {
    final date = event["date"] ?? "";
    final time = event["time"] ?? "00:00";
    return DateTime.tryParse("$date $time") ?? DateTime(2100);
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String dayGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (isSameDay(target, today)) return "Today";
    if (isSameDay(target, tomorrow)) return "Tomorrow";

    return "${_monthName(date.month)} ${date.day}, ${date.year}";
  }

  String _monthName(int m) {
    const names = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return names[m];
  }

  Widget buildAvatarCluster(List<String> selectedKeys) {
    final users = selectedKeys.map((k) => usersBox.get(k)).toList();

    if (users.length == 1) {
      final u = users.first;
      return Row(
        children: [
          CircleAvatar(
            radius: 14,
            child: Icon(
              IconData(u["avatar"], fontFamily: 'MaterialIcons'),
              size: 18,
            ),
          ),
          const SizedBox(width: 6),
          Text(u["name"], style: const TextStyle(fontSize: 16)),
        ],
      );
    }

    final maxToShow = 3;
    final visible = users.take(maxToShow).toList();
    final extra = users.length - maxToShow;

    return SizedBox(
      width: 70,
      height: 30,
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              right: i * 20,
              child: CircleAvatar(
                radius: 14,
                child: Icon(
                  IconData(visible[i]["avatar"], fontFamily: 'MaterialIcons'),
                  size: 18,
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              right: maxToShow * 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "+$extra",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openUserSelector() async {
    await showModalBottomSheet(
      context: context,
      builder: (_) =>
          UserSelectorSheet(onSelectionChanged: () => setState(() {})),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedKeys = List<String>.from(usersBox.get('selectedUserKeys'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('FreeMind'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
              ).then((_) => setState(() {}));
            },
          ),
          GestureDetector(
            onTap: _openUserSelector,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: buildAvatarCluster(selectedKeys),
            ),
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Text('Menu', style: AppText.drawerHeader),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add User'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddUserScreen()),
                ).then((_) => setState(() {}));
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Live Events'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveEventsScreen()),
                );
              },
            ),
          ],
        ),
      ),

      body: ValueListenableBuilder(
        valueListenable: scheduleBox.listenable(),
        builder: (context, box, _) {
          final map = box.toMap();
          final entries = map.entries.where((entry) {
            final event = entry.value as Map;
            final users = List<String>.from(event["users"]);
            return users.any((u) => selectedKeys.contains(u));
          }).toList();

          entries.sort((a, b) {
            final ea = a.value as Map;
            final eb = b.value as Map;
            return parseEventDate(ea).compareTo(parseEventDate(eb));
          });

          if (entries.isEmpty) {
            return const Center(
              child: Text("No events yet", style: TextStyle(fontSize: 18)),
            );
          }

          final Map<String, List<MapEntry>> grouped = {};
          for (final e in entries) {
            final event = e.value as Map;
            final d = parseEventDate(event);
            final label = dayGroupLabel(d);
            grouped.putIfAbsent(label, () => []).add(e);
          }

          final groupKeys = grouped.keys.toList();

          return ListView.builder(
            itemCount: groupKeys.length,
            itemBuilder: (context, groupIndex) {
              final label = groupKeys[groupIndex];
              final groupEvents = grouped[label]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...groupEvents.map((entry) {
                    final event = entry.value as Map;
                    final key = entry.key;
                    return EventCard(
                      event: event,
                      usersBox: usersBox,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScheduleEventDetailsScreen(
                              eventKey: key,
                              event: Map<String, dynamic>.from(event),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddScheduleScreen()),
          ).then((_) => setState(() {}));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
