import 'package:flutter/material.dart';
import 'package:meetbank/models/Events.dart';
import 'package:meetbank/screens/create_event_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  void _navigateAndAddEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventScreen()),
    );
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!.docs
              .map((doc) => Event.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          if (events.isEmpty) {
            return _buildEmptyState();
          } else {
            return _buildEventList(events);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndAddEvent,
        backgroundColor: const Color(0xFFB993D6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.celebration_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          const Text(
            'No Events Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first event.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<Event> events) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${event.getFormattedDate()} • ${event.getFormattedTime()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  event.venue,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
