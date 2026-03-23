import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late Box usersBox;
  late Box scheduleBox;

  @override
  void initState() {
    super.initState();
    usersBox = Hive.box('users');
    scheduleBox = Hive.box('schedule');
  }

  // ⭐ FIXED: Ticketmaster public URL
  String? getTicketUrl() {
    return widget.event["url"]; // <-- Correct field
  }

  // ⭐ Add event to schedule
  void addToSchedule() {
    final selectedKeys = List<String>.from(
      usersBox.get('selectedUserKeys', defaultValue: ['main']),
    );

    final event = widget.event;

    final name = event["name"] ?? "Untitled Event";
    final date = event["dates"]?["start"]?["localDate"] ?? "";
    final time = event["dates"]?["start"]?["localTime"] ?? "";
    final venue = event["_embedded"]?["venues"]?[0]?["name"] ?? "";
    final city = event["_embedded"]?["venues"]?[0]?["city"]?["name"] ?? "";
    final image = event["images"]?[0]?["url"];

    final eventData = {
      "title": name,
      "date": date,
      "time": time,
      "venue": venue,
      "city": city,
      "image": image,
      "users": selectedKeys,
      "source": "ticketmaster",
      "createdAt": DateTime.now().toString(),
    };

    scheduleBox.add(eventData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event added to your schedule")),
    );
  }

  // ⭐ User selector popup
  void openUserSelector() {
    final keys = usersBox.keys.where((k) => k != 'selectedUserKeys').toList();
    List<String> selectedKeys = List<String>.from(
      usersBox.get('selectedUserKeys'),
    );

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Text("Select Users", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),

                ...keys.map((key) {
                  final user = usersBox.get(key);
                  final isSelected = selectedKeys.contains(key);

                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        IconData(user["avatar"], fontFamily: 'MaterialIcons'),
                      ),
                    ),
                    title: Text(user["name"]),
                    trailing: GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          selectedKeys.remove(key);
                        } else {
                          selectedKeys.add(key);
                        }

                        if (selectedKeys.isEmpty) {
                          selectedKeys.add('main');
                        }

                        usersBox.put('selectedUserKeys', selectedKeys);

                        setSheetState(() {});
                        setState(() {});
                      },
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.blue : Colors.grey,
                        size: 26,
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    final name = event["name"] ?? "No title";
    final date = event["dates"]?["start"]?["localDate"] ?? "";
    final time = event["dates"]?["start"]?["localTime"] ?? "";
    final image = event["images"]?[0]?["url"];
    final venue = event["_embedded"]?["venues"]?[0]?["name"] ?? "";
    final city = event["_embedded"]?["venues"]?[0]?["city"]?["name"] ?? "";
    final country =
        event["_embedded"]?["venues"]?[0]?["country"]?["name"] ?? "";

    final ticketUrl = getTicketUrl();

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: openUserSelector,
          ),
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
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          const SizedBox(height: 20),

          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Text("$date  $time", style: const TextStyle(fontSize: 16)),

          const SizedBox(height: 10),

          Text(
            "$venue — $city, $country",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),

          const SizedBox(height: 30),

          // ⭐ BOOK TICKETS (now works)
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text("Book Tickets"),
            onPressed: ticketUrl == null
                ? null
                : () async {
                    final uri = Uri.parse(ticketUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
          ),

          const SizedBox(height: 16),

          // ⭐ ADD TO SCHEDULE
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add to My Schedule"),
            onPressed: addToSchedule,
          ),
        ],
      ),
    );
  }
}
