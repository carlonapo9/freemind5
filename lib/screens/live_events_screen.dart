import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'event_details_screen.dart'; // ⭐ NEW IMPORT

class LiveEventsScreen extends StatefulWidget {
  const LiveEventsScreen({super.key});

  @override
  State<LiveEventsScreen> createState() => _LiveEventsScreenState();
}

class _LiveEventsScreenState extends State<LiveEventsScreen> {
  static const String _apiKey = "Ida9o7QcmvMa6tkU4GCoNBmtlin16N6G";

  bool isLoading = true;
  List<dynamic> events = [];

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    final url = Uri.parse(
      "https://app.ticketmaster.com/discovery/v2/events.json?apikey=$_apiKey&size=20",
    );

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
              ? const Center(child: Text('No events found'))
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];

                    final name = event["name"] ?? "No title";
                    final date = event["dates"]?["start"]?["localDate"] ?? "";
                    final time = event["dates"]?["start"]?["localTime"] ?? "";
                    final image = event["images"]?[0]?["url"];
                    final venue =
                        event["_embedded"]?["venues"]?[0]?["name"] ?? "";
                    final city = event["_embedded"]?["venues"]?[0]?["city"]
                            ?["name"] ??
                        "";
                    final country =
                        event["_embedded"]?["venues"]?[0]?["country"]
                                ?["name"] ??
                            "";

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
                                "$date  $time",
                                style: const TextStyle(fontSize: 14),
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
