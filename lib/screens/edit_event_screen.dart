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

  late Box scheduleBox;
  late Box usersBox;

  List<String> selectedUserKeys = [];

  // Recurrence
  String recurrence = "none";
  List<int> customDays = [];

  late bool isLiveEvent;

  @override
  void initState() {
    super.initState();
    scheduleBox = Hive.box('schedule');
    usersBox = Hive.box('users');

    // Detect live event
    isLiveEvent = widget.event["image"] != null || widget.event["city"] != null;

    titleController = TextEditingController(text: widget.event["title"] ?? "");
    dateController = TextEditingController(text: widget.event["date"] ?? "");
    timeController = TextEditingController(text: widget.event["time"] ?? "");
    venueController = TextEditingController(text: widget.event["venue"] ?? "");

    recurrence = widget.event["recurrence"] ?? "none";
    customDays = List<int>.from(widget.event["customDays"] ?? []);

    selectedUserKeys = List<String>.from(widget.event["users"] ?? ['main']);
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    timeController.dispose();
    venueController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // Toggle attendees
  // -------------------------------------------------------------
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

  // -------------------------------------------------------------
  // Recurrence popup
  // -------------------------------------------------------------
  void openRecurrencePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Recurrence",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    title: const Text("None"),
                    trailing: recurrence == "none"
                        ? const Icon(Icons.check, color: Colors.teal)
                        : null,
                    onTap: () {
                      setState(() => recurrence = "none");
                      Navigator.pop(context);
                    },
                  ),

                  ListTile(
                    title: const Text("Daily"),
                    trailing: recurrence == "daily"
                        ? const Icon(Icons.check, color: Colors.teal)
                        : null,
                    onTap: () {
                      setState(() => recurrence = "daily");
                      Navigator.pop(context);
                    },
                  ),

                  ListTile(
                    title: const Text("Weekly"),
                    trailing: recurrence == "weekly"
                        ? const Icon(Icons.check, color: Colors.teal)
                        : null,
                    onTap: () {
                      setState(() => recurrence = "weekly");
                      Navigator.pop(context);
                    },
                  ),

                  ListTile(
                    title: const Text("Monthly"),
                    trailing: recurrence == "monthly"
                        ? const Icon(Icons.check, color: Colors.teal)
                        : null,
                    onTap: () {
                      setState(() => recurrence = "monthly");
                      Navigator.pop(context);
                    },
                  ),

                  ListTile(
                    title: const Text("Custom Days"),
                    trailing: recurrence == "custom"
                        ? const Icon(Icons.check, color: Colors.teal)
                        : null,
                    onTap: () {
                      setSheetState(() => recurrence = "custom");
                    },
                  ),

                  if (recurrence == "custom") ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: List.generate(7, (i) {
                        const labels = [
                          "Mon",
                          "Tue",
                          "Wed",
                          "Thu",
                          "Fri",
                          "Sat",
                          "Sun",
                        ];
                        final day = i + 1;
                        final selected = customDays.contains(day);

                        return ChoiceChip(
                          label: Text(labels[i]),
                          selected: selected,
                          onSelected: (_) {
                            setSheetState(() {
                              selected
                                  ? customDays.remove(day)
                                  : customDays.add(day);
                            });
                            setState(() {});
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Done"),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // Save event
  // -------------------------------------------------------------
  void save() async {
    final updated = Map<String, dynamic>.from(widget.event);

    if (isLiveEvent) {
      // Only attendees editable
      updated["users"] = selectedUserKeys;
    } else {
      // Full editing allowed
      updated["title"] = titleController.text.trim();
      updated["date"] = dateController.text.trim();
      updated["time"] = timeController.text.trim();
      updated["venue"] = venueController.text.trim();

      updated["recurrence"] = recurrence;
      updated["customDays"] = customDays;

      updated["users"] = selectedUserKeys;
    }

    await scheduleBox.put(widget.eventKey, updated);
    if (mounted) Navigator.pop(context);
  }

  void deleteEvent() async {
    await scheduleBox.delete(widget.eventKey);
    if (mounted) Navigator.pop(context);
  }

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final userKeys = usersBox.keys
        .where((k) => k != 'selectedUserKeys')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Event"),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: save),
          IconButton(icon: const Icon(Icons.delete), onPressed: deleteEvent),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TITLE
          TextField(
            controller: titleController,
            enabled: !isLiveEvent,
            decoration: const InputDecoration(labelText: "Title"),
          ),
          const SizedBox(height: 12),

          // DATE
          TextField(
            controller: dateController,
            enabled: !isLiveEvent,
            decoration: const InputDecoration(labelText: "Date (YYYY-MM-DD)"),
          ),
          const SizedBox(height: 12),

          // TIME
          TextField(
            controller: timeController,
            enabled: !isLiveEvent,
            decoration: const InputDecoration(labelText: "Time (HH:MM)"),
          ),
          const SizedBox(height: 12),

          // VENUE
          TextField(
            controller: venueController,
            enabled: !isLiveEvent,
            decoration: const InputDecoration(labelText: "Venue"),
          ),
          const SizedBox(height: 12),

          // RECURRENCE (manual schedules only)
          if (!isLiveEvent) ...[
            Text("Recurrence", style: Theme.of(context).textTheme.titleMedium),
            ListTile(
              title: Text(
                recurrence == "none"
                    ? "None"
                    : recurrence == "custom"
                    ? "Custom: ${customDays.join(",")}"
                    : recurrence[0].toUpperCase() + recurrence.substring(1),
              ),
              trailing: const Icon(Icons.repeat),
              onTap: openRecurrencePicker,
            ),
            const SizedBox(height: 20),
          ],

          // ATTENDEES
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
              trailing: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Colors.teal : Colors.grey,
              ),
              onTap: () => toggleUser(key),
            );
          }).toList(),

          const SizedBox(height: 20),

          ElevatedButton(onPressed: save, child: const Text("Save Changes")),
        ],
      ),
    );
  }
}
