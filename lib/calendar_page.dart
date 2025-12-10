import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'like_service.dart';
import 'notifications_page.dart';

// THEME COLORS
const tkoBrown = Color(0xFF6A3B1A);
const tkoCream = Color(0xFFF7F2EC);

class TkoEvent {
  final String day;
  final String time;
  final String title;
  final String entry;
  final String prize;

  TkoEvent({
    required this.day,
    required this.time,
    required this.title,
    required this.entry,
    required this.prize,
  });
}

//KO Weekly Event Schedule
final List<TkoEvent> tkoEvents = [
  // TUESDAY
  TkoEvent(
    day: "TUE",
    time: "6:30 PM",
    title: "Pokémon – Standard",
    entry: "\$5 Entry",
    prize: "100% Store Credit Prizing",
  ),
  TkoEvent(
    day: "TUE",
    time: "6:30 PM",
    title: "One Piece – Standard",
    entry: "\$10 Entry",
    prize: "100% Store Credit Prizing",
  ),

  // WEDNESDAY
  TkoEvent(
    day: "WED",
    time: "6:00 PM",
    title: "Yu-Gi-Oh – Genesis (100pt)",
    entry: "\$5 Entry",
    prize: "100% Store Credit Prizing",
  ),
  TkoEvent(
    day: "WED",
    time: "6:30 PM",
    title: "Riftbound LoL – Standard",
    entry: "\$5 Entry",
    prize: "100% Store Credit Prizing",
  ),

  // THURSDAY
  TkoEvent(
    day: "THU",
    time: "6:30 PM",
    title: "One Piece – Standard",
    entry: "\$10 Entry",
    prize: "50% Store Credit + Pack",
  ),

  // FRIDAY
  TkoEvent(
    day: "FRI",
    time: "6:00 PM",
    title: "Yu-Gi-Oh – Advanced",
    entry: "\$5 Entry",
    prize: "100% Store Credit Prizing",
  ),
  TkoEvent(
    day: "FRI",
    time: "6:30 PM",
    title: "MTG – Standard",
    entry: "\$5 Entry",
    prize: "100% Store Credit Prizing",
  ),
  TkoEvent(
    day: "FRI",
    time: "5:00 PM",
    title: "Commander – Free Drop-In",
    entry: "FREE",
    prize: "",
  ),

  // SATURDAY
  TkoEvent(
    day: "SAT",
    time: "12:00 PM",
    title: "Pokémon – Standard",
    entry: "\$5 Entry",
    prize: "100% Store Credit Prizing",
  ),
  TkoEvent(
    day: "SAT",
    time: "2:00 PM",
    title: "Riftbound – Standard",
    entry: "\$5 Entry",
    prize: "100% Store Credit Prizing",
  ),

  // SUNDAY
  TkoEvent(
    day: "SUN",
    time: "12:00 PM",
    title: "Commander – Free Drop-In",
    entry: "FREE",
    prize: "",
  ),
  TkoEvent(
    day: "SUN",
    time: "2:00 PM",
    title: "Gundam – Standard",
    entry: "\$5 Entry",
    prize: "100% Store Credit Prizing",
  ),
];

//EVENT TILE WIDGET
class CalendarEventTile extends StatelessWidget {
  final TkoEvent event;

  const CalendarEventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: tkoBrown,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.time.split(" ").first,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  event.time.split(" ").last,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // EVENT CARD
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: tkoOrange.withOpacity(.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),

                  // CONTENT
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: tkoBrown,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (event.prize.isNotEmpty)
                                Text(
                                  event.prize,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),

                              Text(
                                event.entry,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

//CALENDAR PAGE
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: tkoBrown),
        title: Text(
          'Weekly Events',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
            icon: const Icon(Icons.notifications_none, color: tkoBrown,),
          ),
        ],
      ),

      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: LikeService.likedItemsStream(),
        builder: (context, snap) {
          final wishlistCount = snap.data?.docs.length ?? 0;

          return TkoBottomNav(
            index: -1,
            wishlistCount: wishlistCount,
            onChanged: (newIndex) {
              if (newIndex == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              }
              if (newIndex == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HomePage(initialTab: 1)),
                );
              }
              if (newIndex == 3) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HomePage(initialTab: 3)),
                );
              }
            },
          );
        },
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tkoEvents.length,
        itemBuilder: (context, index) {
          final event = tkoEvents[index];

          final bool isFirstOfDay = index == 0 ||
              tkoEvents[index - 1].day != event.day;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isFirstOfDay)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 20),
                  child: Row(
                    children: [
                      Text(
                        event.day.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: tkoBrown,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Divider(
                          color: Colors.black26,
                          thickness: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

              CalendarEventTile(event: event),
            ],
          );
        },
      ),
    );
  }
}
