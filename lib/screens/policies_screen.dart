import 'package:flutter/material.dart';
import 'package:meetbank/models/Policies.dart';
import 'package:meetbank/screens/create_policies_screen.dart';

class PoliciesScreen extends StatefulWidget {
  const PoliciesScreen({super.key});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> {
  final List<Policy> _policies = [];
  List<Policy> _filteredPolicies = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredPolicies = _policies;
    _searchController.addListener(_filterPolicies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPolicies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPolicies = _policies.where((policy) {
        return policy.title.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _navigateAndAddPolicy() async {
    final newPolicy = await Navigator.push<Policy>(
      context,
      MaterialPageRoute(builder: (context) => const CreatePolicyScreen()),
    );

    if (newPolicy != null) {
      setState(() {
        _policies.add(newPolicy);
        _filterPolicies();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Policies",
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: _filteredPolicies.isEmpty
                ? _buildEmptyState()
                : _buildPolicyList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndAddPolicy,
        backgroundColor: const Color(0xFFB993D6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search policies by title...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isEmpty
                ? Icons.description_outlined
                : Icons.search_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isEmpty ? 'No Policies Found' : 'No Results Found',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Tap the + button to create your first policy.'
                : 'Try a different search term.',
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

  Widget _buildPolicyList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredPolicies.length,
      itemBuilder: (context, index) {
        final policy = _filteredPolicies[index];
        return _buildPolicyCard(policy);
      },
    );
  }

  Widget _buildPolicyCard(Policy policy) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    policy.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(policy.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              policy.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(policy.getCategoryLabel(), Icons.category_outlined, const Color(0xFFB993D6)),
                const SizedBox(width: 8),
                _buildInfoChip('v${policy.version}', Icons.numbers_outlined, const Color(0xFF8CA6DB)),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Effective: ${policy.getFormattedEffectiveDate()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Implement policy details view
                  },
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFFB993D6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'draft':
        color = Colors.orange;
        label = 'Draft';
        break;
      case 'under_review':
        color = Colors.blue;
        label = 'Review';
        break;
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

   Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
