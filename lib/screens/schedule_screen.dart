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

  @override
  void initState() {
    super.initState();
    usersBox = Hive.box('users');

    if (usersBox.isEmpty) {
      usersBox.put('main', {"name": "Me", "avatar": Icons.person.codePoint});
      usersBox.put('selectedUserKeys', ['main']);
    }

    if (!usersBox.containsKey('selectedUserKeys')) {
      usersBox.put('selectedUserKeys', ['main']);
    }
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

    // ⭐ Multi-user cluster
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

                    //  TAP ON NAME → SINGLE SELECT + CLOSE POPUP
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

                      // ⭐ DOT ON THE RIGHT SIDE
                      trailing: GestureDetector(
                        onTap: () {
                          if (isSelected) {
                            selectedKeys.remove(key);
                          } else {
                            selectedKeys.add(key);
                          }

                          // ⭐ Never allow empty selection
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

      body: const Center(
        child: Text(
          'Your events will appear here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
