import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'like_service.dart';

class CalendarEventsPage extends StatefulWidget {
  const CalendarEventsPage({super.key});

  @override
  State<CalendarEventsPage> createState() => _CalendarEventsPageState();
}

class _CalendarEventsPageState extends State<CalendarEventsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool showListView = false;

  // EVENT DATA FROM FIREBASE
  Map<DateTime, List<EventData>> events = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadEventsFromFirebase();
  }

  /// ------------------------------------------------------------
  /// FIREBASE EVENT LOADING
  /// ------------------------------------------------------------
  Future<void> loadEventsFromFirebase() async {
    final snap = await FirebaseFirestore.instance
        .collection("events")
        .orderBy("date")
        .get();

    final Map<DateTime, List<EventData>> temp = {};

    for (var doc in snap.docs) {
      final data = doc.data();

      // SUPPORTS STRING OR TIMESTAMP DATE
      DateTime date;
      if (data["date"] is Timestamp) {
        date = (data["date"] as Timestamp).toDate();
      } else {
        date = DateTime.parse(data["date"]);
      }

      final cleanDate = DateTime(date.year, date.month, date.day);

      temp.putIfAbsent(cleanDate, () => []);

      temp[cleanDate]!.add(
        EventData(
          title: data["title"] ?? "",
          time: data["time"] ?? "",
          prize: data["prize"] ?? "",
          entry: data["entry"] ?? "",
        ),
      );
    }

    setState(() {
      events = temp;
      loading = false;
    });
  }

  List<EventData> _getEventsForDay(DateTime day) {
    return events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    // SHOW LOADING WHILE FETCHING FROM FIREBASE
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final selectedEvents =
    _selectedDay == null ? [] : _getEventsForDay(_selectedDay!);

    return Scaffold(
      backgroundColor: tkoCream,

      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: tkoBrown),
        title: Text(
          'Upcoming Events',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: tkoBrown,
          ),
        ),

        // ICON-ONLY TOGGLE BUTTON
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => showListView = !showListView),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: showListView
                      ? Colors.orange.withOpacity(.18)
                      : Colors.black.withOpacity(.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: showListView
                        ? Colors.orange
                        : Colors.black.withOpacity(.2),
                  ),
                ),
                child: Icon(
                  showListView ? Icons.calendar_month : Icons.view_list,
                  size: 22,
                  color: showListView ? Colors.orange : Colors.black87,
                ),
              ),
            ),
          )
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

      body: Column(
        children: [
          if (!showListView) ...[
            // CALENDAR VIEW
            TableCalendar(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.teal.withOpacity(.75),
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // LIST VIEW MODE (Grouped by date)
          if (showListView)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: (events.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key)))
                    .map((entry) {
                  final date = entry.key;
                  final eventList = entry.value;

                  final month = _monthName(date.month);
                  final day = date.day;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DATE HEADER WITH BREAK LINE
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Text(
                              "$month $day",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: tkoBrown,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Divider(
                                color: Colors.black26,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      ...eventList
                          .map((e) => EventListTile(event: e))
                          .toList(),
                    ],
                  );
                }).toList(),
              ),
            )

          // SELECTED DAY EVENTS (Calendar Mode)
          else
            Expanded(
              child: selectedEvents.isEmpty
                  ? Center(
                child: Text(
                  "No events on this day.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: selectedEvents.length,
                itemBuilder: (_, index) =>
                    EventListTile(event: selectedEvents[index]),
              ),
            ),
        ],
      ),
    );
  }

  // MONTH NAME HELPER
  String _monthName(int m) {
    const months = [
      "", "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];
    return months[m];
  }
}

// EVENT MODEL
class EventData {
  final String title;
  final String time;
  final String prize;
  final String entry;

  EventData({
    required this.title,
    required this.time,
    required this.prize,
    required this.entry,
  });
}

// EVENT CARD UI (unchanged)
class EventListTile extends StatelessWidget {
  final EventData event;

  const EventListTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final timeParts = event.time.split(" ");

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // TIME CIRCLE
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
                Text(timeParts.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
                Text(timeParts.last,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),

          const SizedBox(width: 10),

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
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
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
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54),
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
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
