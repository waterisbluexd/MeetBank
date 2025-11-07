
import 'package:flutter/material.dart';
import 'package:meetbank/models/Policies.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePolicyScreen extends StatefulWidget {
  const CreatePolicyScreen({super.key});

  @override
  State<CreatePolicyScreen> createState() => _CreatePolicyScreenState();
}

class _CreatePolicyScreenState extends State<CreatePolicyScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final versionController = TextEditingController(text: '1.0');
  final documentUrlController = TextEditingController();
  final approvedByController = TextEditingController();
  final departmentController = TextEditingController();
  final audienceController = TextEditingController();
  String? localDocumentPath;
  DateTime? nextReviewDate;

  DateTime? effectiveDate;
  DateTime? expiryDate;
  String selectedCategory = 'administrative';
  String selectedStatus = 'draft';
  List<String> tags = [];
  final tagController = TextEditingController();
  bool _isSaving = false;


  final List<Map<String, dynamic>> categories = [
    {'value': 'hr', 'label': 'Human Resources', 'icon': Icons.people},
    {'value': 'finance', 'label': 'Finance', 'icon': Icons.account_balance},
    {'value': 'it', 'label': 'IT & Security', 'icon': Icons.computer},
    {'value': 'operations', 'label': 'Operations', 'icon': Icons.settings},
    {'value': 'compliance', 'label': 'Compliance', 'icon': Icons.verified_user},
    {'value': 'academic', 'label': 'Academic', 'icon': Icons.school},
    {'value': 'administrative', 'label': 'Administrative', 'icon': Icons.business_center},
  ];

  final List<Map<String, dynamic>> statuses = [
    {'value': 'draft', 'label': 'Draft', 'color': Colors.orange},
    {'value': 'under_review', 'label': 'Under Review', 'color': Colors.blue},
    {'value': 'approved', 'label': 'Approved', 'color': Colors.green},
  ];

  Future<void> _pickDate(bool isEffective, {bool isReview = false}) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: isEffective ? now : (effectiveDate ?? now),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB993D6),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isReview) {
          nextReviewDate = pickedDate;
        } else if (isEffective) {
          effectiveDate = pickedDate;
        } else {
          expiryDate = pickedDate;
        }
      });
    }
  }

  void _addTag() {
    if (tagController.text.trim().isNotEmpty && tags.length < 5) {
      setState(() {
        tags.add(tagController.text.trim());
        tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      tags.remove(tag);
    });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() {
        localDocumentPath = result.files.single.path;
      });
    }
  }

  Future<void> _savePolicy() async {
    if (!_formKey.currentState!.validate() || effectiveDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (expiryDate != null && expiryDate!.isBefore(effectiveDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expiry date must be after effective date'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a policy.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }


    final policy = Policy(
      id: const Uuid().v4(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      category: selectedCategory,
      version: versionController.text.trim(),
      effectiveDate: effectiveDate!,
      expiryDate: expiryDate,
      status: selectedStatus,
      documentUrl: documentUrlController.text.trim(),
      localDocumentPath: localDocumentPath,
      approvedBy: approvedByController.text.trim().isEmpty
          ? 'Pending'
          : approvedByController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags,
      department: departmentController.text.trim(),
      revisionNumber: 1,
      nextReviewDate: nextReviewDate,
      audience: audienceController.text.trim(),
      createdBy: user.uid, // Tagging the policy with the user's ID
    );

    try {
      await FirebaseFirestore.instance
          .collection('policies')
          .doc(policy.id)
          .set(policy.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Policy created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save policy: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }


  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    versionController.dispose();
    documentUrlController.dispose();
    approvedByController.dispose();
    departmentController.dispose();
    audienceController.dispose();
    tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Create New Policy",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 700 : double.infinity),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWeb ? 24 : 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      controller: titleController,
                      label: 'Policy Title',
                      hint: 'e.g., Data Protection Policy',
                      icon: Icons.title,
                      validator: (v) =>
                      v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Description',
                      hint: 'Detailed description of the policy',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Description is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: audienceController,
                      label: 'Audience',
                      hint: 'e.g., All Staff, Faculty Only',
                      icon: Icons.group,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: versionController,
                            label: 'Version',
                            hint: '1.0',
                            icon: Icons.numbers,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Version is required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: departmentController,
                            label: 'Department',
                            hint: 'e.g., IT Department',
                            icon: Icons.business,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Department is required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDocumentPicker(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: documentUrlController,
                      label: 'Document URL (Optional)',
                      hint: 'https://...',
                      icon: Icons.link,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: approvedByController,
                      label: 'Approved By (Optional)',
                      hint: 'Name of approver',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 24),
                    _buildCategorySelector(),
                    const SizedBox(height: 24),
                    _buildStatusSelector(),
                    const SizedBox(height: 24),
                    _buildDateCard(
                      title: 'Effective Date',
                      date: effectiveDate,
                      icon: Icons.event_available,
                      onTap: () => _pickDate(true),
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _buildDateCard(
                      title: 'Next Review Date (Optional)',
                      date: nextReviewDate,
                      icon: Icons.rate_review,
                      onTap: () => _pickDate(false, isReview: true),
                      required: false,
                    ),
                    const SizedBox(height: 12),
                    _buildDateCard(
                      title: 'Expiry Date (Optional)',
                      date: expiryDate,
                      icon: Icons.event_busy,
                      onTap: () => _pickDate(false),
                      required: false,
                    ),
                    const SizedBox(height: 24),
                    _buildTagsSection(),
                    const SizedBox(height: 32),
                     ElevatedButton(
                      onPressed: _isSaving ? null : _savePolicy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB993D6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                          : const Text(
                        "Create Policy",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
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
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFB993D6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFB993D6), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_outlined,
                  color: const Color(0xFFB993D6), size: 20),
              const SizedBox(width: 8),
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final isSelected = selectedCategory == category['value'];
              return InkWell(
                onTap: () {
                  setState(() {
                    selectedCategory = category['value'] as String;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFB993D6).withOpacity(0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFB993D6)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 16,
                        color: isSelected
                            ? const Color(0xFFB993D6)
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFFB993D6)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined,
                  color: const Color(0xFFB993D6), size: 20),
              const SizedBox(width: 8),
              Text(
                'Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses.map((status) {
              final isSelected = selectedStatus == status['value'];
              final color = status['color'] as Color;
              return InkWell(
                onTap: () {
                  setState(() {
                    selectedStatus = status['value'] as String;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    status['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required String title,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null
                ? const Color(0xFFB993D6).withOpacity(0.3)
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFB993D6), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? DateFormat('MMM dd, yyyy').format(date)
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: date != null
                          ? const Color(0xFF1A1A2E)
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (required && date == null)
              const Text(
                'Required',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tag, color: const Color(0xFFB993D6), size: 20),
              const SizedBox(width: 8),
              Text(
                'Tags (Optional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...tags.map((tag) => Chip(
                label: Text(tag),
                onDeleted: () => _removeTag(tag),
                backgroundColor: const Color(0xFFB993D6).withOpacity(0.1),
                deleteIconColor: const Color(0xFFB993D6),
              )),
              if (tags.length < 5)
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: tagController,
                    decoration: InputDecoration(
                      hintText: 'Add a tag...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) => _addTag(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPicker() {
    return InkWell(
      onTap: _pickDocument,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: localDocumentPath != null
                ? const Color(0xFFB993D6).withOpacity(0.3)
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.attach_file, color: Color(0xFFB993D6), size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                localDocumentPath?.split('/').last ?? 'Upload Document',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: localDocumentPath != null
                      ? const Color(0xFF1A1A2E)
                      : Colors.grey.shade400,
                ),
                overflow: TextOverflow.ellipsis,              
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
