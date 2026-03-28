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
  late TextEditingController venueController;
  late TextEditingController dateController;
  late TextEditingController timeController;

  late Box scheduleBox;
  late Box usersBox;

  List<String> selectedUserKeys = [];

  String recurrence = "none";
  List<int> customDays = [];

  int prepMinutes = 0;
  late bool isLiveEvent;

  @override
  void initState() {
    super.initState();
    scheduleBox = Hive.box('schedule');
    usersBox = Hive.box('users');

    isLiveEvent = widget.event["image"] != null || widget.event["city"] != null;

    titleController = TextEditingController(text: widget.event["title"] ?? "");
    venueController = TextEditingController(text: widget.event["venue"] ?? "");
    dateController = TextEditingController(text: widget.event["date"] ?? "");
    timeController = TextEditingController(text: widget.event["time"] ?? "");

    recurrence = widget.event["recurrence"] ?? "none";
    customDays = List<int>.from(widget.event["customDays"] ?? []);
    prepMinutes = widget.event["prepMinutes"] ?? 0;

    selectedUserKeys = List<String>.from(widget.event["users"] ?? ['main']);
  }

  @override
  void dispose() {
    titleController.dispose();
    venueController.dispose();
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }

  String formatPrep(int minutes) {
    if (minutes == 0) return "No alarm";
    if (minutes < 60) return "$minutes minutes";
    return "${minutes ~/ 60}h ${minutes % 60}min";
  }

  String weekdayLabel(int d) {
    const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return labels[d - 1];
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

  Future<void> pickDateTime() async {
    final now = DateTime.now();
    DateTime initial = now;

    if (dateController.text.isNotEmpty && timeController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(
          "${dateController.text} ${timeController.text}",
        );
      } catch (_) {}
    }

    final pickedDate = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: initial,
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );

      if (pickedTime != null) {
        final dt = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          dateController.text =
              "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
          timeController.text =
              "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
        });
      }
    }
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

  void save() async {
    final updated = Map<String, dynamic>.from(widget.event);

    if (isLiveEvent) {
      updated["users"] = selectedUserKeys;
    } else {
      updated["title"] = titleController.text.trim();
      updated["venue"] = venueController.text.trim();
      updated["date"] = dateController.text.trim();
      updated["time"] = timeController.text.trim();
      updated["recurrence"] = recurrence;
      updated["customDays"] = customDays;
      updated["prepMinutes"] = prepMinutes;
      updated["users"] = selectedUserKeys;
    }

    await scheduleBox.put(widget.eventKey, updated);
    if (mounted) Navigator.pop(context);
  }

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
          // ⭐ Title + Location
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    enabled: !isLiveEvent,
                    decoration: const InputDecoration(labelText: "Title"),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: venueController,
                    enabled: !isLiveEvent,
                    decoration: const InputDecoration(labelText: "Location"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ⭐ Date & Time
          Card(
            child: ListTile(
              enabled: !isLiveEvent,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                dateController.text.isEmpty || timeController.text.isEmpty
                    ? "Select Date & Time"
                    : "${dateController.text} • ${timeController.text}",
              ),
              onTap: isLiveEvent ? null : pickDateTime,
            ),
          ),

          const SizedBox(height: 20),

          // ⭐ Alarm
          if (!isLiveEvent)
            Card(
              child: ListTile(
                leading: const Icon(Icons.alarm),
                title: Text(formatPrep(prepMinutes)),
                onTap: pickAlarm,
              ),
            ),

          if (!isLiveEvent) const SizedBox(height: 20),

          // ⭐ Recurrence
          if (!isLiveEvent)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Repeat", style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _recurrenceChip("None", "none"),
                        _recurrenceChip("Daily", "daily"),
                        _recurrenceChip("Weekly", "weekly"),
                        _recurrenceChip("Monthly", "monthly"),
                        _recurrenceChip("Custom", "custom"),
                      ],
                    ),

                    // ⭐ FIXED: Only CUSTOM shows weekday chips
                    if (recurrence == "custom") ...[
                      const SizedBox(height: 12),
                      _weekdayChips(),
                    ],
                  ],
                ),
              ),
            ),

          if (!isLiveEvent) const SizedBox(height: 20),

          // ⭐ Attendees
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

  Widget _recurrenceChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: recurrence == value,
      onSelected: (_) => setState(() => recurrence = value),
    );
  }

  Widget _weekdayChips() {
    const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Wrap(
      spacing: 8,
      children: List.generate(7, (i) {
        final day = i + 1;
        final selected = customDays.contains(day);

        return ChoiceChip(
          label: Text(labels[i]),
          selected: selected,
          onSelected: (_) {
            setState(() {
              selected ? customDays.remove(day) : customDays.add(day);
            });
          },
        );
      }),
    );
  }
}
