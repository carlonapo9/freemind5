import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  late Box usersBox;

  final List<IconData> avatarOptions = [
    Icons.person,
    Icons.face,
    Icons.star,
    Icons.pets,
    Icons.child_care,
    Icons.sports_soccer,
    Icons.work,
    Icons.school,
    Icons.favorite,
    Icons.directions_car,
  ];

  @override
  void initState() {
    super.initState();
    usersBox = Hive.box('users');
  }

  void _editUser(String key, Map user) async {
    final nameCtrl = TextEditingController(text: user["name"]);

    int selectedAvatar = user["avatar"] is int
        ? user["avatar"]
        : int.parse(user["avatar"].toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit User"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl),
                const SizedBox(height: 16),
                const Text("Choose Avatar", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 12,
                  children: avatarOptions.map((icon) {
                    final isSelected = selectedAvatar == icon.codePoint;

                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedAvatar = icon.codePoint;
                        });
                      },
                      child: CircleAvatar(
                        radius: isSelected ? 26 : 22,
                        backgroundColor: isSelected
                            ? Colors.blue
                            : Colors.grey[300],
                        child: Icon(icon, color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      usersBox.put(key, {
        "name": nameCtrl.text.trim(),
        "avatar": selectedAvatar,
      });
      setState(() {});
    }
  }

  void _deleteUser(String key) {
    if (key == "main") return;

    // 1. Delete user from usersBox
    usersBox.delete(key);

    // 2. Update selectedUserKeys
    List<String> selected = List<String>.from(usersBox.get('selectedUserKeys'));
    selected.remove(key);
    if (selected.isEmpty) selected.add('main');
    usersBox.put('selectedUserKeys', selected);

    // 3. Remove user from all schedule events
    final scheduleBox = Hive.box('schedule');
    final events = scheduleBox.toMap();

    for (final entry in events.entries) {
      final eventKey = entry.key;
      final event = Map<String, dynamic>.from(entry.value);

      List<String> users = List<String>.from(event["users"] ?? []);

      if (users.contains(key)) {
        users.remove(key);

        if (users.isEmpty) {
          // 4. Delete event if no users left
          scheduleBox.delete(eventKey);
        } else {
          // Save updated event
          event["users"] = users;
          scheduleBox.put(eventKey, event);
        }
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final keys = usersBox.keys.where((k) => k != 'selectedUserKeys').toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
      body: ListView(
        children: keys.map((key) {
          final user = usersBox.get(key);
          return ListTile(
            title: Text(user["name"]),
            leading: CircleAvatar(
              child: Icon(
                IconData(user["avatar"], fontFamily: 'MaterialIcons'),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editUser(key, user),
                ),
                if (key != "main")
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteUser(key),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
