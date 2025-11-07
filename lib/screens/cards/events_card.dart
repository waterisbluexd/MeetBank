import 'package:flutter/material.dart';
import 'package:meetbank/models/Events.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUpcoming = event.startTime.isAfter(DateTime.now());
    final statusColor = isUpcoming ? const Color(0xFF8CA6DB) : Colors.green;

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
      case 'conference':
        typeIcon = Icons.business_center;
        break;
      case 'meeting':
        typeIcon = Icons.people;
        break;
      case 'ceremony':
        typeIcon = Icons.celebration;
        break;
      case 'presentation':
        typeIcon = Icons.present_to_all;
        break;
      case 'lecture':
        typeIcon = Icons.menu_book;
        break;
      case 'discussion':
        typeIcon = Icons.forum;
        break;
      default:
        typeIcon = Icons.event;
    }

    return Container(
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
    );
  }
}

// Also update the _buildRecentEvents() in HomePage to include these new event types:

Widget _buildRecentEvents() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Recent Activity",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A2E),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        "Latest updates across all records",
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 300,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No recent events'));
            }

            final events = snapshot.data!.docs
                .map((doc) => Event.fromMap(doc.data() as Map<String, dynamic>))
                .toList();

            return ListView.separated(
              itemCount: events.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];

                // Determine icon based on event type
                IconData typeIcon;
                Color iconColor;

                switch (event.eventType.toLowerCase()) {
                  case 'seminar':
                    typeIcon = Icons.school;
                    iconColor = const Color(0xFFB993D6);
                    break;
                  case 'workshop':
                    typeIcon = Icons.construction;
                    iconColor = const Color(0xFF8CA6DB);
                    break;
                  case 'webinar':
                    typeIcon = Icons.wifi;
                    iconColor = const Color(0xFF9C88FF);
                    break;
                  case 'training':
                    typeIcon = Icons.model_training;
                    iconColor = const Color(0xFFFF9A8B);
                    break;
                  case 'conference':
                    typeIcon = Icons.business_center;
                    iconColor = const Color(0xFF6A82FB);
                    break;
                  case 'meeting':
                    typeIcon = Icons.people;
                    iconColor = const Color(0xFF4CAF50);
                    break;
                  case 'ceremony':
                    typeIcon = Icons.celebration;
                    iconColor = const Color(0xFFFF6B9D);
                    break;
                  case 'presentation':
                    typeIcon = Icons.present_to_all;
                    iconColor = const Color(0xFFFF9800);
                    break;
                  case 'lecture':
                    typeIcon = Icons.menu_book;
                    iconColor = const Color(0xFF795548);
                    break;
                  case 'discussion':
                    typeIcon = Icons.forum;
                    iconColor = const Color(0xFF00BCD4);
                    break;
                  default:
                    typeIcon = Icons.event;
                    iconColor = const Color(0xFFB993D6);
                }

                return _buildActivityItem(
                  title: event.title,
                  time: event.getFormattedDate(),
                  type: event.getEventTypeLabel(),
                  icon: typeIcon,
                  iconColor: iconColor,
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildActivityItem({
  required String title,
  required String time,
  required String type,
  required IconData icon,
  required Color iconColor,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 11,
                        color: iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}