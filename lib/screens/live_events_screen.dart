import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';
import 'event_details_screen.dart';

class LiveEventsScreen extends StatefulWidget {
  const LiveEventsScreen({super.key});

  @override
  State<LiveEventsScreen> createState() => _LiveEventsScreenState();
}

class _LiveEventsScreenState extends State<LiveEventsScreen> {
  static const String _apiKey = "Ida9o7QcmvMa6tkU4GCoNBmtlin16N6G";

  bool isLoading = true;
  List<dynamic> events = [];

  double? userLat;
  double? userLng;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  // ⭐ SAME DATE FORMAT AS INTERNAL EVENTS
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

  // ⭐ Haversine (miles)
  double distanceMiles(double lat1, double lon1, double lat2, double lon2) {
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

  Future<void> fetchEvents() async {
    setState(() => isLoading = true);

    // ⭐ 1. Get phone location FIRST
    try {
      final pos = await LocationService().getCurrentPosition();
      userLat = pos.latitude;
      userLng = pos.longitude;
    } catch (e) {
      print("Location unavailable, falling back to global search");
    }

    // ⭐ 2. Build API URL with optional lat/long
    final params = {"apikey": _apiKey, "size": "20", "sort": "date,asc"};

    if (userLat != null && userLng != null) {
      params["latlong"] = "$userLat,$userLng";
      params["radius"] = "3"; // ⭐ 3 miles
    }

    final url = Uri.parse(
      "https://app.ticketmaster.com/discovery/v2/events.json",
    ).replace(queryParameters: params);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final embedded = data["_embedded"];
        final eventsData = embedded?["events"] ?? [];

        setState(() {
          isLoading = false;
          events = eventsData;
        });
      } else {
        setState(() {
          isLoading = false;
          events = [];
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        events = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Events')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
          ? const Center(child: Text('No events found within 3 miles'))
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];

                final name = event["name"] ?? "No title";
                final date = event["dates"]?["start"]?["localDate"];
                final time = event["dates"]?["start"]?["localTime"];
                final formatted = formatDateTime(date, time);

                final image = event["images"]?[0]?["url"];
                final venue = event["_embedded"]?["venues"]?[0]?["name"] ?? "";
                final city =
                    event["_embedded"]?["venues"]?[0]?["city"]?["name"] ?? "";
                final country =
                    event["_embedded"]?["venues"]?[0]?["country"]?["name"] ??
                    "";

                // ⭐ Extract venue lat/lng
                final venueLat = double.tryParse(
                  event["_embedded"]?["venues"]?[0]?["location"]?["latitude"] ??
                      "",
                );
                final venueLng = double.tryParse(
                  event["_embedded"]?["venues"]?[0]?["location"]?["longitude"] ??
                      "",
                );

                double? distance;
                if (userLat != null &&
                    userLng != null &&
                    venueLat != null &&
                    venueLng != null) {
                  distance = distanceMiles(
                    userLat!,
                    userLng!,
                    venueLat,
                    venueLng,
                  );
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailsScreen(event: event),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (image != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                image,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),

                          const SizedBox(height: 10),

                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(formatted, style: const TextStyle(fontSize: 14)),

                          if (distance != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "${distance.toStringAsFixed(1)} miles away",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.teal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                          const SizedBox(height: 6),

                          Text(
                            "$venue — $city, $country",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
