import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meetbank/auth_service.dart';
import 'package:meetbank/models/Events.dart';
import 'package:meetbank/models/Meeting.dart';
import 'package:meetbank/models/Policies.dart';
import 'package:meetbank/screens/create_event_screen.dart';
import 'package:meetbank/screens/create_meeting_screen.dart';
import 'package:meetbank/screens/events_screen.dart';
import 'package:meetbank/screens/meetings_screen.dart';
import 'package:meetbank/screens/policies_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _handleRefresh() async {
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("MeetBank"),
      ),
      drawer: _buildDrawer(context, user),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard Header
                const Text(
                  "Dashboard",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Welcome back! Here's an overview of your institutional records.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats Cards
                _buildStatsGrid(),
                const SizedBox(height: 28),

                // Upcoming Meetings
                _buildUpcomingMeetings(),
                const SizedBox(height: 28),

                // Recent Events
                _buildRecentEvents(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, User user) {
    return Drawer(
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFB993D6),
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Text(
                    (user.displayName ?? "U")[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName ?? "User",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? "",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Main Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard_outlined,
                  title: "Dashboard",
                  isSelected: true,
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.calendar_today_outlined,
                  title: "Meetings",
                  onTap: () {
                    Navigator.pop(context); // Close the drawer first
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MeetingsScreen(),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.event_note_outlined,
                  title: "Events",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EventsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  title: "Policies",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PoliciesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: Colors.grey[300]),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "QUICK ACTIONS",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildQuickAction(
                  title: "Create Meeting",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateMeetingScreen(),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
                _buildQuickAction(
                  title: "Add Event",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateEventScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickAction(
                  title: "Upload Policy",
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Logout Button at Bottom
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  AuthService().signOut();
                },
                icon: const Icon(Icons.logout, size: 20),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red[700],
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFB993D6).withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFFB993D6) : Colors.grey[700],
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFFB993D6) : const Color(
                0xFF1A1A2E),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('meetings').snapshots(),
      builder: (context, meetingSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').snapshots(),
          builder: (context, eventSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('policies')
                  .snapshots(),
              builder: (context, policySnapshot) {
                if (!meetingSnapshot.hasData || !eventSnapshot.hasData ||
                    !policySnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final meetingCount = meetingSnapshot.data!.docs.length;
                final eventCount = eventSnapshot.data!.docs.length;
                final policyCount = policySnapshot.data!.docs.length;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: "Total Meetings",
                            value: meetingCount.toString(),
                            icon: Icons.calendar_today,
                            iconColor: const Color(0xFFB993D6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: "Upcoming Events",
                            value: eventCount.toString(),
                            icon: Icons.event_note,
                            iconColor: const Color(0xFF8CA6DB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: "Active Policies",
                            value: policyCount.toString(),
                            icon: Icons.description,
                            iconColor: const Color(0xFFB993D6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: "Meetings",
                            value: meetingCount.toString(),
                            icon: Icons.people,
                            iconColor: const Color(0xFF8CA6DB),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMeetings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upcoming Meetings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Your scheduled meetings for the next 7 days",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('meetings')
                .where('endTime', isGreaterThan: DateTime.now().toIso8601String())
                .orderBy('endTime')
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No upcoming meetings'));
              }

              var meetings = snapshot.data!.docs
                  .map((doc) =>
                  Meeting.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();

              final now = DateTime.now();
              meetings.sort((a, b) {
                final aIsOngoing = a.startTime.isBefore(now) && a.endTime.isAfter(now);
                final bIsOngoing = b.startTime.isBefore(now) && b.endTime.isAfter(now);
                if (aIsOngoing && !bIsOngoing) return -1;
                if (!aIsOngoing && bIsOngoing) return 1;
                return a.startTime.compareTo(b.startTime);
              });

              return ScrollConfiguration(
                behavior: const DragScrollBehavior(),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: meetings.length,
                  itemBuilder: (context, index) {
                    final meeting = meetings[index];
                    return Container(
                      width: kIsWeb ? 320 : MediaQuery
                          .of(context)
                          .size
                          .width * 0.85,
                      margin: EdgeInsets.only(
                        right: 12,
                        left: index == 0 ? 0 : 0,
                      ),
                      child: _buildMeetingCard(
                        context,
                        meeting: meeting,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingCard(BuildContext context, {required Meeting meeting}) {
    final now = DateTime.now();
    final isOngoing = meeting.startTime.isBefore(now) && meeting.endTime.isAfter(now);
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
            children: [
              Expanded(
                child: Text(
                  meeting.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isOngoing ? Colors.green : const Color(0xFF8CA6DB)).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOngoing ? 'Ongoing' : meeting.status,
                  style: TextStyle(
                    fontSize: 11,
                    color: isOngoing ? Colors.green : const Color(0xFF8CA6DB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                meeting.getFormattedDate(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
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
                meeting.getFormattedTime(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MeetingsScreen(),
                  ),
                ).then((_) => setState(() {}));
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "View Details",
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Replace the _buildRecentEvents() method in your HomePage with this updated version:

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
                  .map((doc) =>
                  Event.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();

              return ListView.separated(
                itemCount: events.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final event = events[index];

                  // Determine icon based on event type (same logic as EventCard)
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
                    default:
                      typeIcon = Icons.event_note;
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
}
// Keep your existing _buildActivityItem method as is
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

class DragScrollBehavior extends MaterialScrollBehavior {
  const DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}
