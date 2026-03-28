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

  DateTime? selectedDateTime;
  int prepMinutes = 0;

  String recurrence = "none";
  List<int> customDays = [];

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

  // -------------------------------------------------------------
  // Formatting
  // -------------------------------------------------------------
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

    return "${weekdays[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} • "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String formatPrep(int minutes) {
    if (minutes == 0) return "No alarm";
    if (minutes < 60) return "$minutes minutes";
    return "${minutes ~/ 60}h ${minutes % 60}min";
  }

  String customDaysLabel(List<int> days) {
    const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days.map((d) => labels[d - 1]).join(", ");
  }

  // ⭐ Compute alarm clock time
  String alarmClockTime() {
    if (selectedDateTime == null) return "";
    if (prepMinutes == 0) return "";

    final alarm = selectedDateTime!.subtract(Duration(minutes: prepMinutes));
    final hh = alarm.hour.toString().padLeft(2, '0');
    final mm = alarm.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  // -------------------------------------------------------------
  // Pickers
  // -------------------------------------------------------------
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

  // -------------------------------------------------------------
  // Save event
  // -------------------------------------------------------------
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

      "recurrence": recurrence,
      "customDays": customDays,

      "prepMinutes": prepMinutes,
    };

    scheduleBox.add(event);
    Navigator.pop(context);
  }

  // -------------------------------------------------------------
  // User selector
  // -------------------------------------------------------------
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

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final alarmTimeText = alarmClockTime();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Schedule")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ⭐ Title + Location
          _sectionCard(
            children: [
              _inputField(titleCtrl, "Title", Icons.title),
              const SizedBox(height: 12),
              _inputField(venueCtrl, "Location", Icons.place),
            ],
          ),

          const SizedBox(height: 20),

          // ⭐ Date & Time
          _sectionCard(
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  selectedDateTime == null
                      ? "Select Date & Time"
                      : formatDateTime(selectedDateTime!),
                ),
                onTap: pickDateTime,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ⭐ Alarm (slider + alarm time top right)
          _sectionCard(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alarm),
                      const SizedBox(width: 12),
                      Text(
                        prepMinutes == 0
                            ? "No alarm"
                            : "${formatPrep(prepMinutes)} before",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  if (alarmTimeText.isNotEmpty)
                    Text(
                      alarmTimeText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal,
                      ),
                    ),
                ],
              ),

              Slider(
                min: 0,
                max: 300,
                divisions: 300,
                value: prepMinutes.toDouble(),
                onChanged: (v) => setState(() => prepMinutes = v.toInt()),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ⭐ Users (avatars + names)
          _sectionCard(
            children: [
              Row(
                children: [
                  const Icon(Icons.people),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: selectedUsers.map((key) {
                        final u = usersBox.get(key);
                        if (u == null) return const SizedBox.shrink();

                        return GestureDetector(
                          onTap: openUserSelector,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                child: Icon(
                                  IconData(
                                    u["avatar"],
                                    fontFamily: 'MaterialIcons',
                                  ),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                u["name"],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: openUserSelector,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ⭐ Recurrence (inline chips)
          _sectionCard(
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

              if (recurrence == "custom") ...[
                const SizedBox(height: 12),
                _weekdayChips(),
              ],
            ],
          ),

          const SizedBox(height: 32),

          ElevatedButton(onPressed: saveEvent, child: const Text("Save")),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // UI Helpers
  // -------------------------------------------------------------
  Widget _sectionCard({required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
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
