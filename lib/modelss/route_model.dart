class BusRoute {
  final String id;
  final String name;
  final String startPoint;
  final String endPoint;
  final List<String> stopIds;
  final String status;
  final int totalBuses;
  final String? color;

  const BusRoute({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.stopIds,
    this.status = 'Active',
    this.totalBuses = 0,
    this.color,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      startPoint: json['startPoint']?.toString() ?? '',
      endPoint: json['endPoint']?.toString() ?? '',
      stopIds:
          (json['stopIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: json['status']?.toString() ?? 'Active',
      totalBuses: (json['totalBuses'] as num?)?.toInt() ?? 0,
      color: json['color']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'stopIds': stopIds,
      'status': status,
      'totalBuses': totalBuses,
      'color': color,
    };
  }

  BusRoute copyWith({
    String? id,
    String? name,
    String? startPoint,
    String? endPoint,
    List<String>? stopIds,
    String? status,
    int? totalBuses,
    String? color,
  }) {
    return BusRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      stopIds: stopIds ?? this.stopIds,
      status: status ?? this.status,
      totalBuses: totalBuses ?? this.totalBuses,
      color: color ?? this.color,
    );
  }
}
