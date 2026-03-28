import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/location_service.dart';
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

  double? userLat;
  double? userLng;
  double? distanceMilesValue;

  @override
  void initState() {
    super.initState();
    scheduleBox = Hive.box('schedule');
    usersBox = Hive.box('users');
    _loadLocationAndDistance();
  }

  // ⭐ Clean location builder (NO DASH unless both exist)
  String buildLocation(String venue, String city) {
    venue = venue.trim();
    city = city.trim();

    if (venue.isEmpty && city.isEmpty) return "";
    if (venue.isEmpty) return city;
    if (city.isEmpty) return venue;
    return "$venue — $city";
  }

  Future<void> _loadLocationAndDistance() async {
    try {
      final pos = await LocationService().getCurrentPosition();
      userLat = pos.latitude;
      userLng = pos.longitude;

      final vLat = widget.event["lat"];
      final vLng = widget.event["lng"];

      if (vLat != null && vLng != null) {
        distanceMilesValue = _distanceMiles(userLat!, userLng!, vLat, vLng);
      }

      setState(() {});
    } catch (e) {
      print("Distance unavailable: $e");
    }
  }

  double _distanceMiles(double lat1, double lon1, double lat2, double lon2) {
    const R = 3958.8;
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  String formatDateTime(String date, String time) {
    if (date.isEmpty || time.isEmpty) return "";

    final parts = date.split("-");
    final t = time.split(":");

    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;

    final hour = int.tryParse(t[0]) ?? 0;
    final minute = int.tryParse(t[1]) ?? 0;

    final dt = DateTime(year, month, day, hour, minute);

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

  String alarmTime(String date, String time, int minutesBefore) {
    final dt = DateTime.parse("$date $time");
    final alarm = dt.subtract(Duration(minutes: minutesBefore));
    return "${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}";
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
    final prepMinutes = event["prepMinutes"] ?? 0;

    final recurrence = event["recurrence"] ?? "none";
    final customDays = List<int>.from(event["customDays"] ?? []);

    String recurrenceText = "";
    if (recurrence == "custom") {
      const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      final days = customDays.map((d) => labels[d - 1]).join(", ");
      recurrenceText = "Repeats: $days";
    } else if (recurrence != "none") {
      recurrenceText =
          "Repeats: ${recurrence[0].toUpperCase()}${recurrence.substring(1)}";
    }

    final alarmLabel = formatPrep(prepMinutes);
    final locationText = buildLocation(venue, city);

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
              Text(
                formatDateTime(date, time),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),

          if (prepMinutes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.alarm, size: 18, color: Colors.deepOrange),
                  const SizedBox(width: 6),
                  Text(
                    "Alarm: $alarmLabel before (${alarmTime(date, time, prepMinutes)})",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ⭐ FIXED: Only show icon + row if location or distance exists
          if (locationText.isNotEmpty || distanceMilesValue != null)
            Row(
              children: [
                if (locationText.isNotEmpty) const Icon(Icons.place, size: 18),

                if (locationText.isNotEmpty) const SizedBox(width: 6),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (locationText.isNotEmpty)
                        Text(
                          locationText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                      if (distanceMilesValue != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "${distanceMilesValue!.toStringAsFixed(1)} miles away",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),

          if (recurrenceText.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.repeat, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    recurrenceText,
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
