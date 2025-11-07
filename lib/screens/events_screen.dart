import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:meetbank/models/Events.dart';
import 'package:meetbank/screens/cards/events_card.dart';
import 'package:meetbank/screens/create_event_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateAndAddEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventScreen()),
    );
  }

  void _editEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateEventScreen(event: event)),
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(String eventId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this event?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                _deleteEvent(eventId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.background,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').orderBy('startTime').snapshots(),
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
            return _buildEventsList(events);
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndAddEvent,
        label: const Text("New Event"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? "No events found" : "No events match your search",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isEmpty)
            Text(
              "Create your first event to get started",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<Event> events) {
    final now = DateTime.now();
    List<Event> filteredEvents = events.where((event) {
      return event.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final ongoing = filteredEvents.where((e) => e.startTime.isBefore(now) && e.endTime.isAfter(now)).toList();
    final upcoming = filteredEvents.where((e) => e.startTime.isAfter(now)).toList();
    final past = filteredEvents.where((e) => e.endTime.isBefore(now)).toList();

    ongoing.sort((a, b) => a.startTime.compareTo(b.startTime));
    upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
    past.sort((a, b) => b.startTime.compareTo(a.startTime));

    final sortedEvents = [...ongoing, ...upcoming, ...past];

    if (sortedEvents.isEmpty) {
      return _buildEmptyState();
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
              return EventCard(
                event: event,
                onEdit: () => _editEvent(event),
                onDelete: () => _showDeleteConfirmationDialog(event.id),
              );
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
          child: EventCard(
            event: event,
            onEdit: () => _editEvent(event),
            onDelete: () => _showDeleteConfirmationDialog(event.id),
          ),
        );
      },
    );
  }
}
