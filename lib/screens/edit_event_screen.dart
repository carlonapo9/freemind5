import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EditEventScreen extends StatefulWidget {
  final dynamic eventKey;
  final Map<String, dynamic> event;

  const EditEventScreen({
    super.key,
    required this.eventKey,
    required this.event,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late TextEditingController titleController;
  late TextEditingController dateController;
  late TextEditingController timeController;
  late TextEditingController venueController;
  late TextEditingController cityController;

  late Box scheduleBox;
  late Box usersBox;

  List<String> selectedUserKeys = [];

  @override
  void initState() {
    super.initState();
    scheduleBox = Hive.box('schedule');
    usersBox = Hive.box('users');

    titleController =
        TextEditingController(text: widget.event["title"] ?? "");
    dateController = TextEditingController(text: widget.event["date"] ?? "");
    timeController = TextEditingController(text: widget.event["time"] ?? "");
    venueController =
        TextEditingController(text: widget.event["venue"] ?? "");
    cityController = TextEditingController(text: widget.event["city"] ?? "");

    selectedUserKeys =
        List<String>.from(widget.event["users"] ?? ['main']);
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    timeController.dispose();
    venueController.dispose();
    cityController.dispose();
    super.dispose();
  }

  void toggleUser(String key) {
    setState(() {
      if (selectedUserKeys.contains(key)) {
        selectedUserKeys.remove(key);
      } else {
        selectedUserKeys.add(key);
      }
      if (selectedUserKeys.isEmpty) {
        selectedUserKeys.add('main');
      }
    });
  }

  void save() async {
    final updated = {
      ...widget.event,
      "title": titleController.text.trim(),
      "date": dateController.text.trim(),
      "time": timeController.text.trim(),
      "venue": venueController.text.trim(),
      "city": cityController.text.trim(),
      "users": selectedUserKeys,
    };

    await scheduleBox.put(widget.eventKey, updated);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userKeys =
        usersBox.keys.where((k) => k != 'selectedUserKeys').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Event"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: "Title"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dateController,
            decoration: const InputDecoration(labelText: "Date (YYYY-MM-DD)"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: timeController,
            decoration: const InputDecoration(labelText: "Time (HH:MM)"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: venueController,
            decoration: const InputDecoration(labelText: "Venue"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cityController,
            decoration: const InputDecoration(labelText: "City"),
          ),
          const SizedBox(height: 20),
          const Text(
            "Attendees",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...userKeys.map((key) {
            final user = usersBox.get(key);
            final isSelected = selectedUserKeys.contains(key);
            return ListTile(
              leading: CircleAvatar(
                child: Icon(
                  IconData(user["avatar"], fontFamily: 'MaterialIcons'),
                ),
              ),
              title: Text(user["name"]),
              trailing: IconButton(
                icon: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: isSelected ? Colors.teal : Colors.grey,
                ),
                onPressed: () => toggleUser(key),
              ),
              onTap: () => toggleUser(key),
            );
          }).toList(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: save,
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }
}
