class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool hasResidentProfile;
  final String? flatNo;
  final String? blockNo;
  final String? floorNo;
  final String? floorName;
  final String? buildingName;
  final String? societyName;
  final int? residentId;
  final int? buildingId;
  final int? flatId;
  final String? profilePicture;
  final String? residentRole;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.hasResidentProfile,
    this.flatNo,
    this.blockNo,
    this.floorNo,
    this.floorName,
    this.buildingName,
    this.societyName,
    this.residentId,
    this.buildingId,
    this.flatId,
    this.profilePicture,
    this.residentRole,
  });

  bool get isAdmin => role == 'admin' || residentRole == 'admin';

  bool get isGuard => role == 'guard';

  bool get isResident => role == 'resident';

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final resident = json['resident'] as Map<String, dynamic>?;
    final flat = resident != null
        ? resident['flat'] as Map<String, dynamic>?
        : null;
    final floor = flat != null
        ? flat['floor'] as Map<String, dynamic>?
        : null;
    final block = floor != null
        ? floor['block'] as Map<String, dynamic>?
        : null;
    var building = block != null
        ? block['building'] as Map<String, dynamic>?
        : null;
    
    // For guards/admins without resident, check for direct building relationship
    if (building == null && json['building'] != null) {
      building = json['building'] as Map<String, dynamic>?;
    }

    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      hasResidentProfile: resident != null,
      flatNo: flat != null ? flat['flat_number']?.toString() : null,
      blockNo: block != null ? block['name']?.toString() : null,
      floorNo: floor != null ? floor['floor_number']?.toString() : null,
      floorName: floor != null ? 'Floor ${floor['floor_number']}' : null,
      buildingName: building != null ? building['name']?.toString() : null,
      societyName: building != null ? building['name']?.toString() : null,
      residentId: resident != null ? resident['id'] as int? : null,
      buildingId: _toInt(json['building_id']) ?? _toInt(building?['id']),
      flatId: resident != null ? _toInt(resident['flat_id']) : null,
      profilePicture: json['profile_picture']?.toString(),
      residentRole: resident != null ? resident['role']?.toString() : null,
    );
  }
}
