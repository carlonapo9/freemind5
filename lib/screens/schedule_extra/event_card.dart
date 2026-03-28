import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EventCard extends StatelessWidget {
  final Map event;
  final Box usersBox;
  final VoidCallback? onTap;

  // ⭐ distance in miles (optional)
  final double? distanceMiles;

  const EventCard({
    super.key,
    required this.event,
    required this.usersBox,
    this.onTap,
    this.distanceMiles,
  });

  // ⭐ Same formatting as AddScheduleScreen
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

    return "${weekdays[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} – "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  // ⭐ Alarm time formatter
  String alarmTime(String date, String time, int minutesBefore) {
    final dt = DateTime.parse("$date $time");
    final alarm = dt.subtract(Duration(minutes: minutesBefore));
    return "${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final image = event["image"];
    final title = event["title"] ?? "";
    final date = event["date"] ?? "";
    final time = event["time"] ?? "";
    final venue = event["venue"] ?? "";
    final city = event["city"] ?? "";

    final recurrence = event["recurrence"] ?? "none";
    final customDays = List<int>.from(event["customDays"] ?? []);

    final prepMinutes = event["prepMinutes"] ?? 0;

    final users = List<String>.from(event["users"] ?? []);

    // ⭐ USERS → avatars + names
    final userWidgets = users.map((key) {
      final u = usersBox.get(key);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            child: Icon(
              IconData(u["avatar"], fontFamily: 'MaterialIcons'),
              size: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            u["name"],
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 10),
        ],
      );
    }).toList();

    // ⭐ Recurrence formatting
    String recurrenceText = "";
    if (recurrence == "custom") {
      const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      final days = customDays.map((d) => labels[d - 1]).join(", ");
      recurrenceText = "Repeats: $days";
    } else if (recurrence != "none") {
      recurrenceText =
          "Repeats: ${recurrence[0].toUpperCase()}${recurrence.substring(1)}";
    }

    final formattedDateTime = formatDateTime(date, time);

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null && image.toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  image,
                  height: 70,
                  width: 70,
                  fit: BoxFit.cover,
                ),
              ),

            if (image != null && image.toString().isNotEmpty)
              const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(children: userWidgets),

                  const SizedBox(height: 8),

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(formattedDateTime, style: const TextStyle(fontSize: 14)),

                  if (distanceMiles != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "${distanceMiles!.toStringAsFixed(1)} miles away",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 4),

                  if (venue.isNotEmpty || city.isNotEmpty)
                    Text(
                      city.isNotEmpty ? "$venue — $city" : venue,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),

                  const SizedBox(height: 4),

                  if (recurrenceText.isNotEmpty)
                    Text(
                      recurrenceText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  // ⭐ ALARM DISPLAY
                  if (prepMinutes > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Alarm: $prepMinutes min before (${alarmTime(date, time, prepMinutes)})",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}
