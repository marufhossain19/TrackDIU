// ====================================================
// models/bus_model.dart — Bus data model
// Note: Using Hive's raw box (Map) instead of typed adapters
//       to avoid build_runner dependency conflicts.
// ====================================================
// Models for TrackDIU — no external imports needed

class BusModel {
  final String id;
  final String number;
  final String route;
  final List<String> stops;
  final bool isActive;
  final String? deviceId;

  const BusModel({
    required this.id,
    required this.number,
    required this.route,
    required this.stops,
    this.isActive = false,
    this.deviceId,
  });

  /// Create from Supabase row map
  factory BusModel.fromMap(Map<String, dynamic> map) {
    return BusModel(
      id: map['id']?.toString() ?? '',
      number: map['number'] as String? ?? '',
      route: map['route'] as String? ?? '',
      stops: List<String>.from(map['stops'] as List? ?? []),
      isActive: map['is_active'] as bool? ?? false,
      deviceId: map['device_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id'       : id,
    'number'   : number,
    'route'    : route,
    'stops'    : stops,
    'is_active': isActive,
    'device_id': deviceId,
  };

  BusModel copyWith({
    String? id,
    String? number,
    String? route,
    List<String>? stops,
    bool? isActive,
    String? deviceId,
  }) {
    return BusModel(
      id      : id ?? this.id,
      number  : number ?? this.number,
      route   : route ?? this.route,
      stops   : stops ?? this.stops,
      isActive: isActive ?? this.isActive,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

class BusWithSchedule {
  final BusModel bus;
  final List<String> departureTimes;

  BusWithSchedule({required this.bus, required this.departureTimes});
}

// ====================================================
// models/schedule_model.dart — Schedule data model
// ====================================================
class ScheduleModel {
  final String id;
  final String busId;
  final String departureTime; // "07:00"
  final String destination;
  final String origin;

  const ScheduleModel({
    required this.id,
    required this.busId,
    required this.departureTime,
    required this.destination,
    required this.origin,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id           : map['id']?.toString() ?? '',
      busId        : map['bus_id']?.toString() ?? '',
      departureTime: map['departure_time'] as String? ?? '',
      destination  : map['destination'] as String? ?? '',
      origin       : map['origin'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id'            : id,
    'bus_id'        : busId,
    'departure_time': departureTime,
    'destination'   : destination,
    'origin'        : origin,
  };
}

// ====================================================
// models/bus_location_model.dart — Real-time location
// ====================================================
class BusLocationModel {
  final String busId;
  final double latitude;
  final double longitude;
  final double? speed;       // km/h
  final String? currentStop;
  final DateTime updatedAt;

  const BusLocationModel({
    required this.busId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.currentStop,
    required this.updatedAt,
  });

  factory BusLocationModel.fromMap(Map<String, dynamic> map) {
    return BusLocationModel(
      busId      : map['bus_id']?.toString() ?? '',
      latitude   : (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude  : (map['longitude'] as num?)?.toDouble() ?? 0.0,
      speed      : (map['speed'] as num?)?.toDouble(),
      currentStop: map['current_stop'] as String?,
      updatedAt  : map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'bus_id'      : busId,
    'latitude'    : latitude,
    'longitude'   : longitude,
    'speed'       : speed,
    'current_stop': currentStop,
    'updated_at'  : updatedAt.toIso8601String(),
  };
}

// ====================================================
// models/chat_message_model.dart — Chatbot message
// ====================================================
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// ====================================================
// models/driver_profile_model.dart — Driver profile
// ====================================================
class DriverProfileModel {
  final String id;
  final String userId;
  final String name;
  final String? busNumber;   // confirmed assigned bus number
  final String? busId;       // confirmed bus UUID

  const DriverProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    this.busNumber,
    this.busId,
  });

  factory DriverProfileModel.fromMap(Map<String, dynamic> map) {
    return DriverProfileModel(
      id       : map['id']?.toString() ?? '',
      userId   : map['user_id']?.toString() ?? '',
      name     : map['name'] as String? ?? '',
      busNumber: map['bus_number'] as String?,
      busId    : map['bus_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id'   : userId,
    'name'      : name,
    'bus_number': busNumber,
    'bus_id'    : busId,
  };
}

// ====================================================
// models/driver_request_model.dart — Bus/Location requests
// ====================================================
class DriverRequestModel {
  final String id;
  final String driverUserId;
  final String driverName;
  final String type;          // 'bus_assignment' | 'location_sharing'
  final String? requestedBus;
  final String? assignedBus;
  final String? assignedBusId;
  final String status;        // 'pending' | 'approved' | 'rejected'
  final String validDate;
  final DateTime createdAt;

  const DriverRequestModel({
    required this.id,
    required this.driverUserId,
    required this.driverName,
    required this.type,
    this.requestedBus,
    this.assignedBus,
    this.assignedBusId,
    required this.status,
    required this.validDate,
    required this.createdAt,
  });

  factory DriverRequestModel.fromMap(Map<String, dynamic> map) {
    return DriverRequestModel(
      id            : map['id']?.toString() ?? '',
      driverUserId  : map['driver_user_id']?.toString() ?? '',
      driverName    : map['driver_name'] as String? ?? '',
      type          : map['type'] as String? ?? '',
      requestedBus  : map['requested_bus'] as String?,
      assignedBus   : map['assigned_bus'] as String?,
      assignedBusId : map['assigned_bus_id']?.toString(),
      status        : map['status'] as String? ?? 'pending',
      validDate     : map['valid_date']?.toString() ?? '',
      createdAt     : map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  bool get isPending  => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
