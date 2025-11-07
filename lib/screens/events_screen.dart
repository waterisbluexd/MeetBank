import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:meetbank/models/Events.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Event> events = [];

  @override
  void initState() {
    super.initState();
    events = _getDummyEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Events",
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: _buildEventsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newEvent = await Navigator.pushNamed(context, '/create-event');

          if (newEvent != null && newEvent is Event) {
            setState(() {
              events.add(newEvent);
            });
          }
        },
        backgroundColor: const Color(0xFFB993D6),
        icon: const Icon(Icons.add),
        label: const Text(
          "New Event",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    final now = DateTime.now();
    final upcoming = events.where((e) => e.startTime.isAfter(now)).toList();
    final past = events.where((e) => e.startTime.isBefore(now)).toList();

    upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
    past.sort((a, b) => b.startTime.compareTo(a.startTime));

    final sortedEvents = [...upcoming, ...past];

    if (sortedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No events found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Create your first event to get started",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth > 800) {
            crossAxisCount = 2;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 420,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: sortedEvents.length,
            itemBuilder: (context, index) {
              final event = sortedEvents[index];
              return _buildEventCard(event);
            },
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildEventCard(event),
        );
      },
    );
  }

  Widget _buildEventCard(Event event) {
    final isUpcoming = event.startTime.isAfter(DateTime.now());
    final statusColor = isUpcoming ? const Color(0xFF8CA6DB) : Colors.grey;

    IconData typeIcon;
    switch (event.eventType.toLowerCase()) {
      case 'seminar':
        typeIcon = Icons.school;
        break;
      case 'workshop':
        typeIcon = Icons.construction;
        break;
      case 'webinar':
        typeIcon = Icons.wifi;
        break;
      case 'training':
        typeIcon = Icons.model_training;
        break;
      default:
        typeIcon = Icons.business_center;
    }

    return Opacity(
      opacity: isUpcoming ? 1.0 : 0.65,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isUpcoming ? "upcoming" : "completed",
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFB993D6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    typeIcon,
                    size: 14,
                    color: const Color(0xFFB993D6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    event.getEventTypeLabel(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB993D6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        event.getFormattedDate(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        event.getFormattedTime(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.venue,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (event.documentUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (event.documentUrl != null) {
                      final uri = Uri.parse(event.documentUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  },
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: const Text(
                    "View Document",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[300]!),
                    foregroundColor: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to event details
                },
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text(
                  "View Details",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey[300]!),
                  foregroundColor: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    ));
  }

  List<Event> _getDummyEvents() {
    final now = DateTime.now();
    return [
      Event(
        id: const Uuid().v4(),
        title: 'Annual Conference 2025',
        description:
        'Join us for our flagship annual conference featuring keynote speakers, panel discussions, and networking opportunities with industry leaders.',
        startTime: now.add(const Duration(days: 15)),
        venue: 'Main Convention Center, Hall A',
        eventType: 'conference',
        organizer: 'admin',
        createdAt: now,
        documentUrl: 'https://example.com/document.pdf',
      ),
      Event(
        id: const Uuid().v4(),
        title: 'Leadership Workshop',
        description:
        'An intensive workshop focused on developing leadership skills, team management, and strategic thinking for middle and senior management.',
        startTime: now.add(const Duration(days: 7)),
        venue: 'Training Room 3, Building B',
        eventType: 'workshop',
        organizer: 'admin',
        createdAt: now,
      ),
      Event(
        id: const Uuid().v4(),
        title: 'Digital Transformation Seminar',
        description:
        'Explore the latest trends in digital transformation, including AI, cloud computing, and data analytics for modern organizations.',
        startTime: now.add(const Duration(days: 20)),
        venue: 'Auditorium 2',
        eventType: 'seminar',
        organizer: 'admin',
        createdAt: now,
      ),
      Event(
        id: const Uuid().v4(),
        title: 'Cybersecurity Best Practices Webinar',
        description:
        'Learn about the latest cybersecurity threats and best practices to protect your organization in the digital age.',
        startTime: now.add(const Duration(days: 3)),
        venue: 'Online (Zoom)',
        eventType: 'webinar',
        organizer: 'admin',
        createdAt: now,
        documentUrl: 'https://example.com/document.pdf',
      ),
      Event(
        id: const Uuid().v4(),
        title: 'Annual General Meeting 2024',
        description:
        'Annual general meeting to review the past year\'s performance, discuss strategic initiatives, and vote on important organizational matters.',
        startTime: now.subtract(const Duration(days: 30)),
        venue: 'Board Room, Executive Floor',
        eventType: 'conference',
        organizer: 'admin',
        createdAt: now.subtract(const Duration(days: 60)),
        status: 'completed',
      ),
    ];
  }
}