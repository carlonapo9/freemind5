import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final titleCtrl = TextEditingController();
  DateTime? selectedDate;
  late Box usersBox;
  late Box eventsBox;

  List<String> selectedUsers = [];

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
    eventsBox = Hive.box('events');

    selectedUsers = List<String>.from(usersBox.get('selectedUserKeys'));
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: now,
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userKeys = usersBox.keys
        .where((k) => k != 'selectedUserKeys')
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Event")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Event Title"),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickDate,
              child: Text(
                selectedDate == null
                    ? "Pick Date"
                    : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
              ),
            ),

            const SizedBox(height: 20),
            const Text("Assign to Users", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: userKeys.map((key) {
                final user = usersBox.get(key);
                final isSelected = selectedUsers.contains(key);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedUsers.remove(key);
                      } else {
                        selectedUsers.add(key);
                      }
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: isSelected ? 28 : 24,
                        backgroundColor: isSelected
                            ? Colors.blue
                            : Colors.grey[300],
                        child: Icon(
                          IconData(user["avatar"], fontFamily: 'MaterialIcons'),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(user["name"]),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                if (selectedDate == null) return;

                final id = DateTime.now().millisecondsSinceEpoch.toString();

                eventsBox.put(id, {
                  "title": titleCtrl.text.trim(),
                  "date": selectedDate!.millisecondsSinceEpoch,
                  "users": selectedUsers,
                });

                Navigator.pop(context);
              },
              child: const Text("Save Event"),
            ),
          ],
        ),
      ),
    );
  }
}
