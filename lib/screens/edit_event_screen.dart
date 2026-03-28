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

  // ⭐ ALARM
  int prepMinutes = 0;

  late bool isLiveEvent;

  @override
  void initState() {
    super.initState();
    scheduleBox = Hive.box('schedule');
    usersBox = Hive.box('users');

    isLiveEvent = widget.event["image"] != null || widget.event["city"] != null;

    titleController = TextEditingController(text: widget.event["title"] ?? "");
    dateController = TextEditingController(text: widget.event["date"] ?? "");
    timeController = TextEditingController(text: widget.event["time"] ?? "");
    venueController = TextEditingController(text: widget.event["venue"] ?? "");

    recurrence = widget.event["recurrence"] ?? "none";
    customDays = List<int>.from(widget.event["customDays"] ?? []);

    // ⭐ LOAD ALARM
    prepMinutes = widget.event["prepMinutes"] ?? 0;

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
  String weekdayLabel(int d) {
    const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return labels[d - 1];
  }

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
                        final day = i + 1;
                        final selected = customDays.contains(day);

                        return ChoiceChip(
                          label: Text(weekdayLabel(day)),
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
  // ⭐ ALARM PICKER
  // -------------------------------------------------------------
  String formatPrep(int minutes) {
    if (minutes < 60) return "$minutes minutes";
    return "${minutes ~/ 60}h ${minutes % 60}min";
  }

  Future<void> pickAlarm() async {
    int temp = prepMinutes;

    final result = await showDialog<int>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Alarm Time"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    min: 0,
                    max: 300,
                    divisions: 300,
                    value: temp.toDouble(),
                    label: formatPrep(temp),
                    onChanged: (v) => setStateDialog(() => temp = v.toInt()),
                  ),
                  Text("Alarm: ${formatPrep(temp)} before"),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, temp),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => prepMinutes = result);
    }
  }

  // -------------------------------------------------------------
  // Save event
  // -------------------------------------------------------------
  void save() async {
    final updated = Map<String, dynamic>.from(widget.event);

    if (isLiveEvent) {
      updated["users"] = selectedUserKeys;
    } else {
      updated["title"] = titleController.text.trim();
      updated["date"] = dateController.text.trim();
      updated["time"] = timeController.text.trim();
      updated["venue"] = venueController.text.trim();

      updated["recurrence"] = recurrence;
      updated["customDays"] = customDays;

      updated["prepMinutes"] = prepMinutes;

      updated["users"] = selectedUserKeys;
    }

    await scheduleBox.put(widget.eventKey, updated);
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
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: save)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: titleController,
            enabled: !isLiveEvent,
            decoration: const InputDecoration(labelText: "Title"),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: dateController,
            enabled: !isLiveEvent,
            decoration: const InputDecoration(labelText: "Date (YYYY-MM-DD)"),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: timeController,
            enabled: !isLiveEvent,
            decoration: const InputDecoration(labelText: "Time (HH:MM)"),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: venueController,
            enabled: !isLiveEvent,
            decoration: const InputDecoration(labelText: "Venue"),
          ),
          const SizedBox(height: 12),

          // ⭐ ALARM
          if (!isLiveEvent) ...[
            Text("Alarm", style: Theme.of(context).textTheme.titleMedium),
            ListTile(
              title: Text(
                prepMinutes == 0
                    ? "No alarm"
                    : "${formatPrep(prepMinutes)} before",
              ),
              trailing: const Icon(Icons.alarm),
              onTap: pickAlarm,
            ),
            const SizedBox(height: 20),
          ],

          // ⭐ RECURRENCE
          if (!isLiveEvent) ...[
            Text("Recurrence", style: Theme.of(context).textTheme.titleMedium),
            ListTile(
              title: Text(
                recurrence == "none"
                    ? "None"
                    : recurrence == "custom"
                    ? "Custom: ${customDays.map(weekdayLabel).join(", ")}"
                    : recurrence[0].toUpperCase() + recurrence.substring(1),
              ),
              trailing: const Icon(Icons.repeat),
              onTap: openRecurrencePicker,
            ),
            const SizedBox(height: 20),
          ],

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
