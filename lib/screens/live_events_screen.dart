import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';
import 'event_details_screen.dart';
import 'schedule_extra/user_selector_sheet.dart';
import '../utils/app_colors.dart'; // ⭐ Make sure this is imported

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

  late Box scheduleBox;
  late Box usersBox;

  List<dynamic> selectedUsers = [];

  @override
  void initState() {
    super.initState();
    scheduleBox = Hive.box('schedule');
    usersBox = Hive.box('users');

    selectedUsers = List<dynamic>.from(usersBox.get('selectedUserKeys'));

    fetchEvents();
  }

  // ⭐ Clean location builder
  String buildLocation(String venue, String city, String country) {
    venue = venue.trim();
    city = city.trim();
    country = country.trim();

    final parts = [
      if (venue.isNotEmpty) venue,
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ];

    return parts.join(", ");
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

    return "${weekdays[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} – "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  // ⭐ Format schedule date/time for warnings
  String formatScheduleDateTime(DateTime dt) {
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

  // ⭐ Grouped conflict detection
  Map<String, List<String>> detectConflicts(DateTime eventStart) {
    final Map<String, List<String>> userWarnings = {};

    for (var key in scheduleBox.keys) {
      final s = scheduleBox.get(key);
      if (s == null) continue;

      final scheduleUsers = List<String>.from(s["users"] ?? []);

      // Only check schedules for selected users
      final involvedUsers = scheduleUsers
          .where((u) => selectedUsers.contains(u))
          .toList();

      if (involvedUsers.isEmpty) continue;

      final sDate = s["date"] ?? "";
      final sTime = s["time"] ?? "";

      if (sDate.isEmpty || sTime.isEmpty) continue;

      final scheduleStart = DateTime.parse("$sDate $sTime");
      final formatted = formatScheduleDateTime(scheduleStart);

      // ⭐ Only show warnings if schedule is same day, day before, or day after
      final dayDiff = scheduleStart.difference(eventStart).inDays;
      if (dayDiff < -1 || dayDiff > 1) continue;

      final diffMinutes = scheduleStart.difference(eventStart).inMinutes;

      for (final uKey in involvedUsers) {
        userWarnings.putIfAbsent(uKey, () => []);

        if (dayDiff == 0) userWarnings[uKey]!.add("Same day ($formatted)");
        if (dayDiff == 1) userWarnings[uKey]!.add("Next day ($formatted)");
        if (dayDiff == -1) userWarnings[uKey]!.add("Day before ($formatted)");

        if (diffMinutes.abs() < 45) {
          userWarnings[uKey]!.add(
            "Only ${diffMinutes.abs()} min between this and ($formatted)",
          );
        }

        if (diffMinutes == 0) {
          userWarnings[uKey]!.add("Overlaps with ($formatted)");
        }
      }
    }

    return userWarnings;
  }

  Future<void> fetchEvents() async {
    setState(() => isLoading = true);

    try {
      final pos = await LocationService().getCurrentPosition();
      userLat = pos.latitude;
      userLng = pos.longitude;
    } catch (_) {}

    final params = {"apikey": _apiKey, "size": "20", "sort": "date,asc"};

    if (userLat != null && userLng != null) {
      params["latlong"] = "$userLat,$userLng";
      params["radius"] = "3";
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
    } catch (_) {
      setState(() {
        isLoading = false;
        events = [];
      });
    }
  }

  // ⭐ Open user selector
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
      backgroundColor: Colors.grey.shade100, // ⭐ Main screen background

      appBar: AppBar(
        backgroundColor: AppColors.primary, // ⭐ Match ScheduleScreen
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Live Events'),
        actions: [
          Row(
            children: selectedUsers.map((key) {
              final u = usersBox.get(key);
              if (u == null) return const SizedBox.shrink();

              return GestureDetector(
                onTap: openUserSelector,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CircleAvatar(
                    radius: 14,
                    child: Icon(
                      IconData(u["avatar"], fontFamily: 'MaterialIcons'),
                      size: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          IconButton(icon: const Icon(Icons.edit), onPressed: openUserSelector),
        ],
      ),

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

                final locationText = buildLocation(venue, city, country);

                DateTime? eventStart;
                if (date != null && time != null) {
                  eventStart = DateTime.parse("$date $time");
                }

                final userWarnings = eventStart != null
                    ? detectConflicts(eventStart)
                    : <String, List<String>>{};

                final hasWarnings = userWarnings.isNotEmpty;

                bool expanded = false;

                return StatefulBuilder(
                  builder: (context, setTileState) {
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

                              Text(
                                formatted,
                                style: const TextStyle(fontSize: 14),
                              ),

                              if (hasWarnings)
                                InkWell(
                                  onTap: () => setTileState(() {
                                    expanded = !expanded;
                                  }),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                        width: 0.6,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "⚠️ Schedule conflicts for ${userWarnings.keys.length} user(s)",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Icon(
                                          expanded
                                              ? Icons.keyboard_arrow_down
                                              : Icons.keyboard_arrow_right,
                                          size: 20,
                                          color: Colors.grey.shade700,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (expanded)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: userWarnings.entries.map((entry) {
                                      final uKey = entry.key;
                                      final messages = entry.value;

                                      final u = usersBox.get(uKey);
                                      final name = u?["name"] ?? uKey;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "$name:",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade900,
                                              ),
                                            ),
                                            ...messages.map(
                                              (m) => Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 10,
                                                  top: 2,
                                                ),
                                                child: Text(
                                                  "• $m",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

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

                              if (locationText.isNotEmpty)
                                Text(
                                  locationText,
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
                );
              },
            ),
    );
  }
}
