/// Trip model representing NEMT ride with AHCCCS compliance fields
class TripModel {
  final String id;
  final String memberId;
  final String? driverId;
  final String? vehicleId;
  
  // Trip details
  final TripType tripType;
  final TripStatus status;
  final DateTime scheduledPickupTime;
  final DateTime? actualPickupTime;
  final DateTime? actualDropoffTime;
  final DateTime? estimatedDropoffTime;
  
  // Pickup location
  final String pickupAddress;
  final String pickupCity;
  final String pickupState;
  final String pickupZip;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? pickupNotes;
  
  // Dropoff location
  final String dropoffAddress;
  final String dropoffCity;
  final String dropoffState;
  final String dropoffZip;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final String? dropoffNotes;
  
  // Trip metadata
  final String? appointmentType; // Medical, Pharmacy, Dialysis, etc.
  final String? facilityName;
  final String? facilityPhone;
  final bool isRecurring;
  final String? recurringSchedule;
  final double? estimatedMiles;
  final double? actualMiles;
  final int? estimatedDuration; // minutes
  final int? actualDuration; // minutes
  
  // Member requirements
  final String mobilityAid; // wheelchair, walker, none, etc.
  final bool requiresAttendant;
  final int attendantCount;
  final bool oxygenRequired;
  final String? specialRequirements;
  
  // AHCCCS compliance
  final String authorizationNumber;
  final String membershipId;
  final DateTime? authorizationExpiry;
  final String priority; // routine, urgent, emergent
  final String? cancellationReason;
  final DateTime? cancellationTime;
  
  // Documentation
  final String? driverSignature;
  final String? memberSignature;
  final List<String>? photoDocumentation;
  final String? pdfReportUrl; // Added
  final String? notes;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  TripModel({
    required this.id,
    required this.memberId,
    this.driverId,
    this.vehicleId,
    required this.tripType,
    required this.status,
    required this.scheduledPickupTime,
    this.actualPickupTime,
    this.actualDropoffTime,
    this.estimatedDropoffTime,
    required this.pickupAddress,
    required this.pickupCity,
    required this.pickupState,
    required this.pickupZip,
    this.pickupLatitude,
    this.pickupLongitude,
    this.pickupNotes,
    required this.dropoffAddress,
    required this.dropoffCity,
    required this.dropoffState,
    required this.dropoffZip,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.dropoffNotes,
    this.appointmentType,
    this.facilityName,
    this.facilityPhone,
    this.isRecurring = false,
    this.recurringSchedule,
    this.estimatedMiles,
    this.actualMiles,
    this.estimatedDuration,
    this.actualDuration,
    this.mobilityAid = 'none',
    this.requiresAttendant = false,
    this.attendantCount = 0,
    this.oxygenRequired = false,
    this.specialRequirements,
    required this.authorizationNumber,
    required this.membershipId,
    this.authorizationExpiry,
    this.priority = 'routine',
    this.cancellationReason,
    this.cancellationTime,
    this.driverSignature,
    this.memberSignature,
    this.photoDocumentation,
    this.pdfReportUrl, // Added
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'driverId': driverId,
    'vehicleId': vehicleId,
    'tripType': tripType.toString(),
    'status': status.toString(),
    'scheduledPickupTime': scheduledPickupTime.toIso8601String(),
    'actualPickupTime': actualPickupTime?.toIso8601String(),
    'actualDropoffTime': actualDropoffTime?.toIso8601String(),
    'estimatedDropoffTime': estimatedDropoffTime?.toIso8601String(),
    'pickupAddress': pickupAddress,
    'pickupCity': pickupCity,
    'pickupState': pickupState,
    'pickupZip': pickupZip,
    'pickupLatitude': pickupLatitude,
    'pickupLongitude': pickupLongitude,
    'pickupNotes': pickupNotes,
    'dropoffAddress': dropoffAddress,
    'dropoffCity': dropoffCity,
    'dropoffState': dropoffState,
    'dropoffZip': dropoffZip,
    'dropoffLatitude': dropoffLatitude,
    'dropoffLongitude': dropoffLongitude,
    'dropoffNotes': dropoffNotes,
    'appointmentType': appointmentType,
    'facilityName': facilityName,
    'facilityPhone': facilityPhone,
    'isRecurring': isRecurring,
    'recurringSchedule': recurringSchedule,
    'estimatedMiles': estimatedMiles,
    'actualMiles': actualMiles,
    'estimatedDuration': estimatedDuration,
    'actualDuration': actualDuration,
    'mobilityAid': mobilityAid,
    'requiresAttendant': requiresAttendant,
    'attendantCount': attendantCount,
    'oxygenRequired': oxygenRequired,
    'specialRequirements': specialRequirements,
    'authorizationNumber': authorizationNumber,
    'membershipId': membershipId,
    'authorizationExpiry': authorizationExpiry?.toIso8601String(),
    'priority': priority,
    'cancellationReason': cancellationReason,
    'cancellationTime': cancellationTime?.toIso8601String(),
    'driverSignature': driverSignature,
    'memberSignature': memberSignature,
    'photoDocumentation': photoDocumentation,
    'pdfReportUrl': pdfReportUrl, // Added
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  
  factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
    id: json['id'] as String,
    memberId: json['memberId'] as String,
    driverId: json['driverId'] as String?,
    vehicleId: json['vehicleId'] as String?,
    tripType: TripType.values.firstWhere((e) => e.toString() == json['tripType']),
    status: TripStatus.values.firstWhere((e) => e.toString() == json['status']),
    scheduledPickupTime: DateTime.parse(json['scheduledPickupTime'] as String),
    actualPickupTime: json['actualPickupTime'] != null ? DateTime.parse(json['actualPickupTime'] as String) : null,
    actualDropoffTime: json['actualDropoffTime'] != null ? DateTime.parse(json['actualDropoffTime'] as String) : null,
    estimatedDropoffTime: json['estimatedDropoffTime'] != null ? DateTime.parse(json['estimatedDropoffTime'] as String) : null,
    pickupAddress: json['pickupAddress'] as String,
    pickupCity: json['pickupCity'] as String,
    pickupState: json['pickupState'] as String,
    pickupZip: json['pickupZip'] as String,
    pickupLatitude: json['pickupLatitude'] as double?,
    pickupLongitude: json['pickupLongitude'] as double?,
    pickupNotes: json['pickupNotes'] as String?,
    dropoffAddress: json['dropoffAddress'] as String,
    dropoffCity: json['dropoffCity'] as String,
    dropoffState: json['dropoffState'] as String,
    dropoffZip: json['dropoffZip'] as String,
    dropoffLatitude: json['dropoffLatitude'] as double?,
    dropoffLongitude: json['dropoffLongitude'] as double?,
    dropoffNotes: json['dropoffNotes'] as String?,
    appointmentType: json['appointmentType'] as String?,
    facilityName: json['facilityName'] as String?,
    facilityPhone: json['facilityPhone'] as String?,
    isRecurring: json['isRecurring'] as bool? ?? false,
    recurringSchedule: json['recurringSchedule'] as String?,
    estimatedMiles: json['estimatedMiles'] as double?,
    actualMiles: json['actualMiles'] as double?,
    estimatedDuration: json['estimatedDuration'] as int?,
    actualDuration: json['actualDuration'] as int?,
    mobilityAid: json['mobilityAid'] as String? ?? 'none',
    requiresAttendant: json['requiresAttendant'] as bool? ?? false,
    attendantCount: json['attendantCount'] as int? ?? 0,
    oxygenRequired: json['oxygenRequired'] as bool? ?? false,
    specialRequirements: json['specialRequirements'] as String?,
    authorizationNumber: json['authorizationNumber'] as String,
    membershipId: json['membershipId'] as String,
    authorizationExpiry: json['authorizationExpiry'] != null ? DateTime.parse(json['authorizationExpiry'] as String) : null,
    priority: json['priority'] as String? ?? 'routine',
    cancellationReason: json['cancellationReason'] as String?,
    cancellationTime: json['cancellationTime'] != null ? DateTime.parse(json['cancellationTime'] as String) : null,
    driverSignature: json['driverSignature'] as String?,
    memberSignature: json['memberSignature'] as String?,
    photoDocumentation: (json['photoDocumentation'] as List<dynamic>?)?.cast<String>(),
    pdfReportUrl: json['pdfReportUrl'] as String?, // Added
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
  
  TripModel copyWith({
    String? id,
    String? memberId,
    String? driverId,
    String? vehicleId,
    TripType? tripType,
    TripStatus? status,
    DateTime? scheduledPickupTime,
    DateTime? actualPickupTime,
    DateTime? actualDropoffTime,
    DateTime? estimatedDropoffTime,
    String? pickupAddress,
    String? pickupCity,
    String? pickupState,
    String? pickupZip,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupNotes,
    String? dropoffAddress,
    String? dropoffCity,
    String? dropoffState,
    String? dropoffZip,
    double? dropoffLatitude,
    double? dropoffLongitude,
    String? dropoffNotes,
    String? appointmentType,
    String? facilityName,
    String? facilityPhone,
    bool? isRecurring,
    String? recurringSchedule,
    double? estimatedMiles,
    double? actualMiles,
    int? estimatedDuration,
    int? actualDuration,
    String? mobilityAid,
    bool? requiresAttendant,
    int? attendantCount,
    bool? oxygenRequired,
    String? specialRequirements,
    String? authorizationNumber,
    String? membershipId,
    DateTime? authorizationExpiry,
    String? priority,
    String? cancellationReason,
    DateTime? cancellationTime,
    String? driverSignature,
    String? memberSignature,
    List<String>? photoDocumentation,
    String? pdfReportUrl, // Added
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TripModel(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    driverId: driverId ?? this.driverId,
    vehicleId: vehicleId ?? this.vehicleId,
    tripType: tripType ?? this.tripType,
    status: status ?? this.status,
    scheduledPickupTime: scheduledPickupTime ?? this.scheduledPickupTime,
    actualPickupTime: actualPickupTime ?? this.actualPickupTime,
    actualDropoffTime: actualDropoffTime ?? this.actualDropoffTime,
    estimatedDropoffTime: estimatedDropoffTime ?? this.estimatedDropoffTime,
    pickupAddress: pickupAddress ?? this.pickupAddress,
    pickupCity: pickupCity ?? this.pickupCity,
    pickupState: pickupState ?? this.pickupState,
    pickupZip: pickupZip ?? this.pickupZip,
    pickupLatitude: pickupLatitude ?? this.pickupLatitude,
    pickupLongitude: pickupLongitude ?? this.pickupLongitude,
    pickupNotes: pickupNotes ?? this.pickupNotes,
    dropoffAddress: dropoffAddress ?? this.dropoffAddress,
    dropoffCity: dropoffCity ?? this.dropoffCity,
    dropoffState: dropoffState ?? this.dropoffState,
    dropoffZip: dropoffZip ?? this.dropoffZip,
    dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
    dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
    dropoffNotes: dropoffNotes ?? this.dropoffNotes,
    appointmentType: appointmentType ?? this.appointmentType,
    facilityName: facilityName ?? this.facilityName,
    facilityPhone: facilityPhone ?? this.facilityPhone,
    isRecurring: isRecurring ?? this.isRecurring,
    recurringSchedule: recurringSchedule ?? this.recurringSchedule,
    estimatedMiles: estimatedMiles ?? this.estimatedMiles,
    actualMiles: actualMiles ?? this.actualMiles,
    estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    actualDuration: actualDuration ?? this.actualDuration,
    mobilityAid: mobilityAid ?? this.mobilityAid,
    requiresAttendant: requiresAttendant ?? this.requiresAttendant,
    attendantCount: attendantCount ?? this.attendantCount,
    oxygenRequired: oxygenRequired ?? this.oxygenRequired,
    specialRequirements: specialRequirements ?? this.specialRequirements,
    authorizationNumber: authorizationNumber ?? this.authorizationNumber,
    membershipId: membershipId ?? this.membershipId,
    authorizationExpiry: authorizationExpiry ?? this.authorizationExpiry,
    priority: priority ?? this.priority,
    cancellationReason: cancellationReason ?? this.cancellationReason,
    cancellationTime: cancellationTime ?? this.cancellationTime,
    driverSignature: driverSignature ?? this.driverSignature,
    memberSignature: memberSignature ?? this.memberSignature,
    photoDocumentation: photoDocumentation ?? this.photoDocumentation,
    pdfReportUrl: pdfReportUrl ?? this.pdfReportUrl, // Added
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum TripType {
  oneWay,
  roundTrip,
  multiStop,
}

enum TripStatus {
  scheduled,
  assigned,
  enRoute,
  arrived,
  pickedUp,
  completed,
  cancelled,
  noShow,
}
