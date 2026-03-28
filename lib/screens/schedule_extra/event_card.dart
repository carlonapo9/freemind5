import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EventCard extends StatelessWidget {
  final Map event;
  final Box usersBox;
  final VoidCallback? onTap;
  final double? distanceMiles;

  const EventCard({
    super.key,
    required this.event,
    required this.usersBox,
    this.onTap,
    this.distanceMiles,
  });

  // ⭐ Clean location builder
  String buildLocation(String venue, String city) {
    venue = venue.trim();
    city = city.trim();

    if (venue.isEmpty && city.isEmpty) return "";
    if (venue.isEmpty) return city;
    if (city.isEmpty) return venue;
    return "$venue — $city";
  }

  // ⭐ Time until event starts
  String timeUntil(String date, String time) {
    if (date.isEmpty || time.isEmpty) return "";

    try {
      final eventTime = DateTime.parse("$date $time");
      final now = DateTime.now();
      Duration diff = eventTime.difference(now);

      // ⭐ Past event
      if (diff.isNegative) {
        diff = diff.abs();
        if (diff.inMinutes < 60) return "Started ${diff.inMinutes} min ago";
        if (diff.inHours < 24) {
          final h = diff.inHours;
          final m = diff.inMinutes % 60;
          return m == 0 ? "Started $h h ago" : "Started $h h $m min ago";
        }
        final d = diff.inDays;
        return "Started $d day${d == 1 ? '' : 's'} ago";
      }

      // ⭐ Future event
      final totalMinutes = diff.inMinutes;
      final totalHours = diff.inHours;
      final totalDays = diff.inDays;

      // Minutes only
      if (totalMinutes < 60) return "Starts in $totalMinutes min";

      // Hours + minutes
      if (totalHours < 24) {
        final h = totalHours;
        final m = totalMinutes % 60;
        return m == 0 ? "Starts in $h h" : "Starts in $h h $m min";
      }

      // Days + hours
      if (totalDays < 30) {
        final d = totalDays;
        final h = totalHours % 24;
        return h == 0
            ? "Starts in $d day${d == 1 ? '' : 's'}"
            : "Starts in $d day${d == 1 ? '' : 's'} $h h";
      }

      // Months + days
      final months = totalDays ~/ 30;
      final days = totalDays % 30;

      if (days == 0) {
        return "Starts in $months month${months == 1 ? '' : 's'}";
      }

      return "Starts in $months month${months == 1 ? '' : 's'} $days day${days == 1 ? '' : 's'}";
    } catch (_) {
      return "";
    }
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

    final userWidgets = users.map((key) {
      final u = usersBox.get(key);
      if (u == null) return const SizedBox.shrink();
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
    final alarmText = formatPrep(prepMinutes);
    final locationText = buildLocation(venue, city);
    final untilText = timeUntil(date, time);

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

                  if (untilText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        untilText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  if (prepMinutes > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "Alarm: $alarmText before",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

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

                  if (locationText.isNotEmpty)
                    Text(
                      locationText,
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
