import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'schedule_extra/user_selector_sheet.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final titleCtrl = TextEditingController();
  final venueCtrl = TextEditingController();
  final recurrenceCtrl = TextEditingController(); // typed recurrence

  DateTime? selectedDateTime;
  int prepMinutes = 0;

  List<dynamic> selectedUsers = [];

  late Box usersBox;
  late Box scheduleBox;

  @override
  void initState() {
    super.initState();
    usersBox = Hive.box('users');
    scheduleBox = Hive.box('schedule');

    selectedUsers = List<dynamic>.from(usersBox.get('selectedUserKeys'));
  }

  String formatDateTime(DateTime dt) {
    const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return "${weekdays[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} – "
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}";
  }

  String formatPrep(int minutes) {
    if (minutes < 60) return "$minutes minutes";
    return "${minutes ~/ 60}h ${minutes % 60}min";
  }

  Future<int?> pickPrepTime() async {
    int temp = prepMinutes;

    return showDialog<int>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Preparation Time"),
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
                  Text("Prep time: ${formatPrep(temp)}"),
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
  }

  Future<void> pickDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: selectedDateTime ?? now,
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedDateTime != null
            ? TimeOfDay(
                hour: selectedDateTime!.hour,
                minute: selectedDateTime!.minute,
              )
            : TimeOfDay.now(),
      );

      if (pickedTime != null) {
        selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {});
      }
    }
  }

  void saveEvent() {
    if (titleCtrl.text.isEmpty || selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill title and date/time")),
      );
      return;
    }

    final event = {
      "title": titleCtrl.text,
      "venue": venueCtrl.text,

      "date":
          "${selectedDateTime!.year}-${selectedDateTime!.month.toString().padLeft(2, '0')}-${selectedDateTime!.day.toString().padLeft(2, '0')}",
      "time":
          "${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}",

      "users": selectedUsers,

      // typed recurrence
      "recurrence": recurrenceCtrl.text.trim(),

      "prepMinutes": prepMinutes,
    };

    scheduleBox.add(event);
    Navigator.pop(context);
  }

  void openUserSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) => UserSelectorSheet(
        onSelectionChanged: () {
          setState(() {
            selectedUsers = List<dynamic>.from(
              usersBox.get('selectedUserKeys'),
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Schedule")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ⭐ TITLE
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: "Title"),
          ),

          const SizedBox(height: 16),

          // ⭐ LOCATION (venue)
          TextField(
            controller: venueCtrl,
            decoration: const InputDecoration(labelText: "Location"),
          ),

          const SizedBox(height: 24),

          // ⭐ DATE & TIME
          Text("Date & Time", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),

          ElevatedButton(
            onPressed: pickDateTime,
            child: Text(
              selectedDateTime == null
                  ? "Select Date & Time"
                  : formatDateTime(selectedDateTime!),
            ),
          ),

          const SizedBox(height: 24),

          // ⭐ ALARM
          Text("Alarm", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              prepMinutes == 0
                  ? "No alarm"
                  : "${formatPrep(prepMinutes)} before",
            ),
            trailing: const Icon(Icons.timer),
            onTap: () async {
              final result = await pickPrepTime();
              if (result != null) {
                setState(() => prepMinutes = result);
              }
            },
          ),

          const SizedBox(height: 24),

          // ⭐ USERS
          Text("Users", style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            title: Text("${selectedUsers.length} selected"),
            trailing: const Icon(Icons.people),
            onTap: openUserSelector,
          ),

          const SizedBox(height: 24),

          // ⭐ RECURRENCE (typed)
          Text(
            "Recurrence (type anything)",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          TextField(
            controller: recurrenceCtrl,
            decoration: const InputDecoration(
              hintText: "e.g. daily, weekly, mon,wed,fri, every 2 weeks",
            ),
          ),

          const SizedBox(height: 32),

          // ⭐ SAVE
          ElevatedButton(onPressed: saveEvent, child: const Text("Save")),
        ],
      ),
    );
  }
}
