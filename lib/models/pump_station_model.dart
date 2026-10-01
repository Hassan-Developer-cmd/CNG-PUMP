enum PumpStatus {
  active,
  inactive;

  String get value => name;

  static PumpStatus fromString(String? value) {
    if (value == null) return PumpStatus.active;
    switch (value.toLowerCase().trim()) {
      case 'inactive':
        return PumpStatus.inactive;
      case 'active':
      default:
        return PumpStatus.active;
    }
  }
}

class PumpStation {
  final String id;
  final String name;
  final String location;
  final int totalPumps;
  final PumpStatus status;
  final List<String> assignedUserIds;
  final List<String> categories;
  final String notes;
  final String? imageUrl;
  final DateTime createdAt;

  const PumpStation({
    required this.id,
    required this.name,
    required this.location,
    required this.totalPumps,
    this.status = PumpStatus.active,
    this.assignedUserIds = const [],
    this.categories = const ['Fuel Pump'],
    this.notes = '',
    this.imageUrl,
    required this.createdAt,
  });

  bool get isActive => status == PumpStatus.active;

  factory PumpStation.fromJson(Map<String, dynamic> json) {
    return PumpStation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      totalPumps: (json['totalPumps'] as num?)?.toInt() ?? 0,
      status: PumpStatus.fromString(json['status'] as String?),
      assignedUserIds: (json['assignedUserIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Fuel Pump'],
      notes: json['notes'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'totalPumps': totalPumps,
      'status': status.value,
      'assignedUserIds': assignedUserIds,
      'categories': categories,
      'notes': notes,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PumpStation copyWith({
    String? id,
    String? name,
    String? location,
    int? totalPumps,
    PumpStatus? status,
    List<String>? assignedUserIds,
    List<String>? categories,
    String? notes,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return PumpStation(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      totalPumps: totalPumps ?? this.totalPumps,
      status: status ?? this.status,
      assignedUserIds: assignedUserIds ?? this.assignedUserIds,
      categories: categories ?? this.categories,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
