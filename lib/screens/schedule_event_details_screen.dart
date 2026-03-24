import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'edit_event_screen.dart';

class ScheduleEventDetailsScreen extends StatefulWidget {
  final dynamic eventKey;
  final Map<String, dynamic> event;

  const ScheduleEventDetailsScreen({
    super.key,
    required this.eventKey,
    required this.event,
  });

  @override
  State<ScheduleEventDetailsScreen> createState() =>
      _ScheduleEventDetailsScreenState();
}

class _ScheduleEventDetailsScreenState
    extends State<ScheduleEventDetailsScreen> {
  late Box scheduleBox;
  late Box usersBox;

  @override
  void initState() {
    super.initState();
    scheduleBox = Hive.box('schedule');
    usersBox = Hive.box('users');
  }

  List<String> attendeeNames() {
    final users = List<String>.from(widget.event["users"] ?? []);

    return users
        .map<String>((key) {
          final u = usersBox.get(key);
          return u != null ? u["name"] : "";
        })
        .where((name) => name.isNotEmpty)
        .toList();
  }

  void deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Event"),
        content: const Text(
          "Are you sure you want to delete this event from your schedule?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await scheduleBox.delete(widget.eventKey);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final image = event["image"];
    final title = event["title"] ?? "Untitled Event";
    final date = event["date"] ?? "";
    final time = event["time"] ?? "";
    final venue = event["venue"] ?? "";
    final city = event["city"] ?? "";
    final attendees = attendeeNames().join(", ");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Details"),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: deleteEvent),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                image,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 6),
              Text("$date  $time"),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "$venue — $city",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.group, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Attending: $attendees",
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text("Edit Event"),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditEventScreen(
                    eventKey: widget.eventKey,
                    event: Map<String, dynamic>.from(event),
                  ),
                ),
              );
              if (mounted) {
                final updated = scheduleBox.get(widget.eventKey);
                if (updated != null) {
                  setState(() {
                    widget.event.clear();
                    widget.event.addAll(
                      Map<String, dynamic>.from(updated as Map),
                    );
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
