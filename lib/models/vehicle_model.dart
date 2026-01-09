/// Vehicle model for fleet management
class VehicleModel {
  final String id;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final String vin;
  final String color;
  final VehicleType type;
  final int capacity;
  final bool wheelchairAccessible;
  final bool hasOxygen;
  final bool isActive;
  
  // Maintenance
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenanceDue;
  final int currentMileage;
  final String? maintenanceNotes;
  
  // Insurance
  final String insuranceProvider;
  final String insurancePolicyNumber;
  final DateTime insuranceExpiry;
  
  // Registration
  final DateTime registrationExpiry;
  final String? registrationState;
  
  // Inspections
  final DateTime? lastInspection;
  final DateTime? nextInspectionDue;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  VehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.vin,
    required this.color,
    required this.type,
    required this.capacity,
    this.wheelchairAccessible = false,
    this.hasOxygen = false,
    this.isActive = true,
    this.lastMaintenance,
    this.nextMaintenanceDue,
    this.currentMileage = 0,
    this.maintenanceNotes,
    required this.insuranceProvider,
    required this.insurancePolicyNumber,
    required this.insuranceExpiry,
    required this.registrationExpiry,
    this.registrationState,
    this.lastInspection,
    this.nextInspectionDue,
    required this.createdAt,
    required this.updatedAt,
  });
  
  String get displayName => '$year $make $model';
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'make': make,
    'model': model,
    'year': year,
    'licensePlate': licensePlate,
    'vin': vin,
    'color': color,
    'type': type.toString(),
    'capacity': capacity,
    'wheelchairAccessible': wheelchairAccessible,
    'hasOxygen': hasOxygen,
    'isActive': isActive,
    'lastMaintenance': lastMaintenance?.toIso8601String(),
    'nextMaintenanceDue': nextMaintenanceDue?.toIso8601String(),
    'currentMileage': currentMileage,
    'maintenanceNotes': maintenanceNotes,
    'insuranceProvider': insuranceProvider,
    'insurancePolicyNumber': insurancePolicyNumber,
    'insuranceExpiry': insuranceExpiry.toIso8601String(),
    'registrationExpiry': registrationExpiry.toIso8601String(),
    'registrationState': registrationState,
    'lastInspection': lastInspection?.toIso8601String(),
    'nextInspectionDue': nextInspectionDue?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  
  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
    id: json['id'] as String,
    make: json['make'] as String,
    model: json['model'] as String,
    year: json['year'] as int,
    licensePlate: json['licensePlate'] as String,
    vin: json['vin'] as String,
    color: json['color'] as String,
    type: VehicleType.values.firstWhere((e) => e.toString() == json['type']),
    capacity: json['capacity'] as int,
    wheelchairAccessible: json['wheelchairAccessible'] as bool? ?? false,
    hasOxygen: json['hasOxygen'] as bool? ?? false,
    isActive: json['isActive'] as bool? ?? true,
    lastMaintenance: json['lastMaintenance'] != null ? DateTime.parse(json['lastMaintenance'] as String) : null,
    nextMaintenanceDue: json['nextMaintenanceDue'] != null ? DateTime.parse(json['nextMaintenanceDue'] as String) : null,
    currentMileage: json['currentMileage'] as int? ?? 0,
    maintenanceNotes: json['maintenanceNotes'] as String?,
    insuranceProvider: json['insuranceProvider'] as String,
    insurancePolicyNumber: json['insurancePolicyNumber'] as String,
    insuranceExpiry: DateTime.parse(json['insuranceExpiry'] as String),
    registrationExpiry: DateTime.parse(json['registrationExpiry'] as String),
    registrationState: json['registrationState'] as String?,
    lastInspection: json['lastInspection'] != null ? DateTime.parse(json['lastInspection'] as String) : null,
    nextInspectionDue: json['nextInspectionDue'] != null ? DateTime.parse(json['nextInspectionDue'] as String) : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
  
  VehicleModel copyWith({
    String? id,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    String? vin,
    String? color,
    VehicleType? type,
    int? capacity,
    bool? wheelchairAccessible,
    bool? hasOxygen,
    bool? isActive,
    DateTime? lastMaintenance,
    DateTime? nextMaintenanceDue,
    int? currentMileage,
    String? maintenanceNotes,
    String? insuranceProvider,
    String? insurancePolicyNumber,
    DateTime? insuranceExpiry,
    DateTime? registrationExpiry,
    String? registrationState,
    DateTime? lastInspection,
    DateTime? nextInspectionDue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => VehicleModel(
    id: id ?? this.id,
    make: make ?? this.make,
    model: model ?? this.model,
    year: year ?? this.year,
    licensePlate: licensePlate ?? this.licensePlate,
    vin: vin ?? this.vin,
    color: color ?? this.color,
    type: type ?? this.type,
    capacity: capacity ?? this.capacity,
    wheelchairAccessible: wheelchairAccessible ?? this.wheelchairAccessible,
    hasOxygen: hasOxygen ?? this.hasOxygen,
    isActive: isActive ?? this.isActive,
    lastMaintenance: lastMaintenance ?? this.lastMaintenance,
    nextMaintenanceDue: nextMaintenanceDue ?? this.nextMaintenanceDue,
    currentMileage: currentMileage ?? this.currentMileage,
    maintenanceNotes: maintenanceNotes ?? this.maintenanceNotes,
    insuranceProvider: insuranceProvider ?? this.insuranceProvider,
    insurancePolicyNumber: insurancePolicyNumber ?? this.insurancePolicyNumber,
    insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
    registrationExpiry: registrationExpiry ?? this.registrationExpiry,
    registrationState: registrationState ?? this.registrationState,
    lastInspection: lastInspection ?? this.lastInspection,
    nextInspectionDue: nextInspectionDue ?? this.nextInspectionDue,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum VehicleType {
  sedan,
  suv,
  van,
  wheelchairVan,
  ambulette,
}
