import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_colors.dart';
import '../utils/app_text.dart';
import 'live_events_screen.dart';
import 'add_user_screen.dart';
import 'manage_users_screen.dart';

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

  // ⭐ Parse event date for sorting
  DateTime parseEventDate(Map event) {
    final date = event["date"] ?? "";
    final time = event["time"] ?? "00:00";
    return DateTime.tryParse("$date $time") ?? DateTime(2100);
  }

  // ⭐ AVATAR CLUSTER FOR APPBAR
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

  void _openUserSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        final keys = usersBox.keys
            .where((k) => k != 'selectedUserKeys')
            .toList();

        List<String> selectedKeys = List<String>.from(
          usersBox.get('selectedUserKeys'),
        );

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Text("Select Users", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),

                ...keys.map((key) {
                  final user = usersBox.get(key);
                  final isSelected = selectedKeys.contains(key);

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      usersBox.put('selectedUserKeys', [key]);
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          IconData(user["avatar"], fontFamily: 'MaterialIcons'),
                          size: 20,
                        ),
                      ),
                      title: Text(user["name"]),
                      trailing: GestureDetector(
                        onTap: () {
                          if (isSelected) {
                            selectedKeys.remove(key);
                          } else {
                            selectedKeys.add(key);
                          }

                          if (selectedKeys.isEmpty) {
                            selectedKeys.add('main');
                          }

                          usersBox.put('selectedUserKeys', selectedKeys);

                          setSheetState(() {});
                          setState(() {});
                        },
                        child: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected ? Colors.blue : Colors.grey,
                          size: 26,
                        ),
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }

  // ⭐ EVENT CARD — small image + attendees
  Widget buildEventCard(Map event) {
    final image = event["image"];
    final title = event["title"];
    final date = event["date"];
    final time = event["time"];
    final venue = event["venue"];
    final city = event["city"];
    final users = List<String>.from(event["users"]);

    // Convert user keys → names
    final attendeeNames = users
        .map((key) {
          final u = usersBox.get(key);
          return u != null ? u["name"] : "";
        })
        .join(", ");

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⭐ SMALL IMAGE
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  image,
                  height: 70,
                  width: 70,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(width: 12),

            // ⭐ TEXT DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text("$date  $time", style: const TextStyle(fontSize: 14)),

                  const SizedBox(height: 4),

                  Text(
                    "$venue — $city",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                  const SizedBox(height: 6),

                  // ⭐ ATTENDEES
                  Text(
                    "Attending: $attendeeNames",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

      // ⭐ SORTED, FILTERED EVENT LIST
      body: ValueListenableBuilder(
        valueListenable: scheduleBox.listenable(),
        builder: (context, box, _) {
          final allEvents = box.values.toList();

          // Filter by selected users
          final filtered = allEvents.where((event) {
            final users = List<String>.from(event["users"]);
            return users.any((u) => selectedKeys.contains(u));
          }).toList();

          // ⭐ SORT BY DATE
          filtered.sort(
            (a, b) => parseEventDate(a).compareTo(parseEventDate(b)),
          );

          if (filtered.isEmpty) {
            return const Center(
              child: Text("No events yet", style: TextStyle(fontSize: 18)),
            );
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return buildEventCard(filtered[index]);
            },
          );
        },
      ),
    );
  }
}
