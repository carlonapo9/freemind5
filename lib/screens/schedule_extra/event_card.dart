import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EventCard extends StatelessWidget {
  final Map event;
  final Box usersBox;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.usersBox,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = event["image"];
    final title = event["title"] ?? "";
    final date = event["date"] ?? "";
    final time = event["time"] ?? "";
    final venue = event["venue"] ?? "";
    final city = event["city"] ?? "";
    final recurrence = event["recurrence"] ?? "";
    final users = List<String>.from(event["users"] ?? []);

    final attendeeNames = users
        .map((key) {
          final u = usersBox.get(key);
          return u != null ? u["name"] : "";
        })
        .where((name) => name.isNotEmpty)
        .join(", ");

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⭐ IMAGE (optional)
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

            // ⭐ TEXT CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // DATE + TIME
                  Text(
                    "$date  $time",
                    style: const TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 4),

                  // VENUE + CITY (city optional)
                  if (venue.isNotEmpty || city.isNotEmpty)
                    Text(
                      city.isNotEmpty ? "$venue — $city" : venue,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),

                  const SizedBox(height: 4),

                  // RECURRENCE (optional)
                  if (recurrence.isNotEmpty)
                    Text(
                      "Repeats: $recurrence",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 6),

                  // USERS
                  Text(
                    "Attending: $attendeeNames",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
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

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}
