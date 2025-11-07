class Policy {
  final String id;
  final String title;
  final String description;
  final String category;
  final String version;
  final DateTime effectiveDate;
  final DateTime? expiryDate;
  final String status; // draft, under_review, approved, archived
  final String? documentUrl;
  final String? localDocumentPath;
  final String approvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String department;
  final int revisionNumber;
  final String? previousVersionId;
  final DateTime? nextReviewDate;
  final String? audience;

  Policy({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.version,
    required this.effectiveDate,
    this.expiryDate,
    this.status = 'draft',
    this.documentUrl,
    this.localDocumentPath,
    required this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    required this.department,
    this.revisionNumber = 1,
    this.previousVersionId,
    this.nextReviewDate,
    this.audience,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'version': version,
      'effectiveDate': effectiveDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'status': status,
      'documentUrl': documentUrl,
      'localDocumentPath': localDocumentPath,
      'approvedBy': approvedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'department': department,
      'revisionNumber': revisionNumber,
      'previousVersionId': previousVersionId,
      'nextReviewDate': nextReviewDate?.toIso8601String(),
      'audience': audience,
    };
  }

  factory Policy.fromMap(Map<String, dynamic> map) {
    return Policy(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      version: map['version'] ?? '',
      effectiveDate: DateTime.parse(map['effectiveDate']),
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate']) : null,
      status: map['status'] ?? 'draft',
      documentUrl: map['documentUrl'],
      localDocumentPath: map['localDocumentPath'],
      approvedBy: map['approvedBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      tags: List<String>.from(map['tags'] ?? []),
      department: map['department'] ?? '',
      revisionNumber: map['revisionNumber'] ?? 1,
      previousVersionId: map['previousVersionId'],
      nextReviewDate: map['nextReviewDate'] != null ? DateTime.parse(map['nextReviewDate']) : null,
      audience: map['audience'],
    );
  }

  String getFormattedEffectiveDate() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[effectiveDate.month - 1]} ${effectiveDate.day}, ${effectiveDate.year}';
  }

  String getFormattedExpiryDate() {
    if (expiryDate == null) return 'No expiry';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[expiryDate!.month - 1]} ${expiryDate!.day}, ${expiryDate!.year}';
  }

  bool isExpired() {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool isActive() {
    final now = DateTime.now();
    final isEffective = now.isAfter(effectiveDate) || now.isAtSameMomentAs(effectiveDate);
    final notExpired = expiryDate == null || now.isBefore(expiryDate!);
    return status == 'approved' && isEffective && notExpired;
  }

  String getStatusLabel() {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'under_review':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'archived':
        return 'Archived';
      default:
        return 'Unknown';
    }
  }

  String getCategoryLabel() {
    switch (category.toLowerCase()) {
      case 'hr':
        return 'Human Resources';
      case 'finance':
        return 'Finance';
      case 'it':
        return 'IT & Security';
      case 'operations':
        return 'Operations';
      case 'compliance':
        return 'Compliance';
      case 'academic':
        return 'Academic';
      case 'administrative':
        return 'Administrative';
      default:
        return category;
    }
  }

  Policy copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? version,
    DateTime? effectiveDate,
    DateTime? expiryDate,
    String? status,
    String? documentUrl,
    String? localDocumentPath,
    String? approvedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? department,
    int? revisionNumber,
    String? previousVersionId,
    DateTime? nextReviewDate,
    String? audience,
  }) {
    return Policy(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      version: version ?? this.version,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      documentUrl: documentUrl ?? this.documentUrl,
      localDocumentPath: localDocumentPath ?? this.localDocumentPath,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      department: department ?? this.department,
      revisionNumber: revisionNumber ?? this.revisionNumber,
      previousVersionId: previousVersionId ?? this.previousVersionId,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      audience: audience ?? this.audience,
    );
  }
}