import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late Box usersBox;
  late Box scheduleBox;

  double? userLat;
  double? userLng;
  double? distanceMilesValue;

  @override
  void initState() {
    super.initState();
    usersBox = Hive.box('users');
    scheduleBox = Hive.box('schedule');
    _loadLocationAndDistance();
  }

  // ⭐ Load user location + compute distance
  Future<void> _loadLocationAndDistance() async {
    try {
      final pos = await LocationService().getCurrentPosition();
      userLat = pos.latitude;
      userLng = pos.longitude;

      final venue = widget.event["_embedded"]?["venues"]?[0];
      final vLat = double.tryParse(venue?["location"]?["latitude"] ?? "");
      final vLng = double.tryParse(venue?["location"]?["longitude"] ?? "");

      if (vLat != null && vLng != null) {
        distanceMilesValue = _distanceMiles(userLat!, userLng!, vLat, vLng);
      }

      setState(() {});
    } catch (e) {
      print("Distance unavailable: $e");
    }
  }

  // ⭐ Haversine formula (miles)
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

  // ⭐ Unified date format
  String formatDateTime(String? date, String? time) {
    if (date == null || time == null) return "";

    final parts = date.split("-");
    if (parts.length != 3) return "";

    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;

    final t = time.split(":");
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

    final w = weekdays[dt.weekday - 1];
    final m = months[dt.month - 1];

    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    return "$w ${dt.day} $m – $hh:$mm";
  }

  // ⭐ Ticket URL
  String? getTicketUrl() => widget.event["url"];

  // ⭐ Save event
  void saveEvent(List<String> selectedKeys) {
    final event = widget.event;

    final name = event["name"] ?? "Untitled Event";
    final date = event["dates"]?["start"]?["localDate"] ?? "";
    final time = event["dates"]?["start"]?["localTime"] ?? "";
    final venue = event["_embedded"]?["venues"]?[0]?["name"] ?? "";
    final city = event["_embedded"]?["venues"]?[0]?["city"]?["name"] ?? "";
    final image = event["images"]?[0]?["url"];

    // ⭐ GET LAT/LNG FROM TICKETMASTER
    final venueData = event["_embedded"]?["venues"]?[0];
    final vLat = double.tryParse(venueData?["location"]?["latitude"] ?? "");
    final vLng = double.tryParse(venueData?["location"]?["longitude"] ?? "");

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

      // ⭐ ADD THESE TWO
      "lat": vLat,
      "lng": vLng,
    };

    scheduleBox.add(eventData);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event added to your schedule")),
    );
  }

  // ⭐ Mandatory user selector
  void openMandatoryUserSelector() {
    final keys = usersBox.keys.where((k) => k != 'selectedUserKeys').toList();
    List<String> selectedKeys = List<String>.from(
      usersBox.get('selectedUserKeys'),
    );

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Who is going?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

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
                          setSheetState(() {});
                        },
                        child: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected ? Colors.blue : Colors.grey,
                          size: 26,
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: selectedKeys.isEmpty
                        ? null
                        : () {
                            usersBox.put('selectedUserKeys', selectedKeys);
                            saveEvent(selectedKeys);
                          },
                    child: const Text("Confirm"),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
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
    final date = event["dates"]?["start"]?["localDate"];
    final time = event["dates"]?["start"]?["localTime"];
    final formatted = formatDateTime(date, time);

    final image = event["images"]?[0]?["url"];
    final venue = event["_embedded"]?["venues"]?[0]?["name"] ?? "";
    final city = event["_embedded"]?["venues"]?[0]?["city"]?["name"] ?? "";
    final country =
        event["_embedded"]?["venues"]?[0]?["country"]?["name"] ?? "";

    final ticketUrl = getTicketUrl();

    return Scaffold(
      appBar: AppBar(title: Text(name)),

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

          Text(formatted, style: const TextStyle(fontSize: 16)),

          if (distanceMilesValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                "${distanceMilesValue!.toStringAsFixed(1)} miles away",
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.teal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(height: 10),

          Text(
            "$venue — $city, $country",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),

          const SizedBox(height: 30),

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

          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add to My Schedule"),
            onPressed: openMandatoryUserSelector,
          ),
        ],
      ),
    );
  }
}
