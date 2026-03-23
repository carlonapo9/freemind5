import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final TextEditingController nameCtrl = TextEditingController();
  int selectedAvatar = Icons.person.codePoint;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add User")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Name"),
            ),

            const SizedBox(height: 20),
            const Text("Choose Avatar", style: TextStyle(fontSize: 16)),

            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: avatarOptions.map((icon) {
                final isSelected = selectedAvatar == icon.codePoint;
                return GestureDetector(
                  onTap: () => setState(() => selectedAvatar = icon.codePoint),
                  child: CircleAvatar(
                    radius: isSelected ? 26 : 22,
                    backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                    child: Icon(icon, color: Colors.white),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final box = Hive.box('users');
                final id = DateTime.now().millisecondsSinceEpoch.toString();

                box.put(id, {
                  "name": name,
                  "avatar": selectedAvatar,
                });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
