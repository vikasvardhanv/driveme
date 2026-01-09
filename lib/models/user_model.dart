/// User model representing drivers, dispatchers, admins, and members
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final UserRole role;
  final String? profileImageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Driver-specific fields
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final List<String>? certifications; // CPR, First Aid, etc.
  final String? vehicleId;
  
  // Member-specific fields
  final String? membershipId;
  final String? dateOfBirth;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? emergencyContact;
  final String? emergencyPhone;
  final List<String>? medicalConditions;
  final String? mobilityAid; // wheelchair, walker, none, etc.
  
  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.licenseNumber,
    this.licenseExpiry,
    this.certifications,
    this.vehicleId,
    this.membershipId,
    this.dateOfBirth,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.emergencyContact,
    this.emergencyPhone,
    this.medicalConditions,
    this.mobilityAid,
  });
  
  String get fullName => '$firstName $lastName';
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
    'role': role.toString(),
    'profileImageUrl': profileImageUrl,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'licenseNumber': licenseNumber,
    'licenseExpiry': licenseExpiry?.toIso8601String(),
    'certifications': certifications,
    'vehicleId': vehicleId,
    'membershipId': membershipId,
    'dateOfBirth': dateOfBirth,
    'address': address,
    'city': city,
    'state': state,
    'zipCode': zipCode,
    'emergencyContact': emergencyContact,
    'emergencyPhone': emergencyPhone,
    'medicalConditions': medicalConditions,
    'mobilityAid': mobilityAid,
  };
  
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    phoneNumber: json['phoneNumber'] as String,
    role: UserRole.values.firstWhere((e) => e.toString() == json['role']),
    profileImageUrl: json['profileImageUrl'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    licenseNumber: json['licenseNumber'] as String?,
    licenseExpiry: json['licenseExpiry'] != null ? DateTime.parse(json['licenseExpiry'] as String) : null,
    certifications: (json['certifications'] as List<dynamic>?)?.cast<String>(),
    vehicleId: json['vehicleId'] as String?,
    membershipId: json['membershipId'] as String?,
    dateOfBirth: json['dateOfBirth'] as String?,
    address: json['address'] as String?,
    city: json['city'] as String?,
    state: json['state'] as String?,
    zipCode: json['zipCode'] as String?,
    emergencyContact: json['emergencyContact'] as String?,
    emergencyPhone: json['emergencyPhone'] as String?,
    medicalConditions: (json['medicalConditions'] as List<dynamic>?)?.cast<String>(),
    mobilityAid: json['mobilityAid'] as String?,
  );
  
  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    UserRole? role,
    String? profileImageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? licenseNumber,
    DateTime? licenseExpiry,
    List<String>? certifications,
    String? vehicleId,
    String? membershipId,
    String? dateOfBirth,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? emergencyContact,
    String? emergencyPhone,
    List<String>? medicalConditions,
    String? mobilityAid,
  }) => UserModel(
    id: id ?? this.id,
    email: email ?? this.email,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    role: role ?? this.role,
    profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    licenseNumber: licenseNumber ?? this.licenseNumber,
    licenseExpiry: licenseExpiry ?? this.licenseExpiry,
    certifications: certifications ?? this.certifications,
    vehicleId: vehicleId ?? this.vehicleId,
    membershipId: membershipId ?? this.membershipId,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    address: address ?? this.address,
    city: city ?? this.city,
    state: state ?? this.state,
    zipCode: zipCode ?? this.zipCode,
    emergencyContact: emergencyContact ?? this.emergencyContact,
    emergencyPhone: emergencyPhone ?? this.emergencyPhone,
    medicalConditions: medicalConditions ?? this.medicalConditions,
    mobilityAid: mobilityAid ?? this.mobilityAid,
  );
}

enum UserRole {
  driver,
  dispatcher,
  admin,
  member,
}
