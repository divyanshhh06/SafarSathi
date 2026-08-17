import 'package:latlong2/latlong.dart';

class District {
  final String slug;
  final String name;
  final int stopCount;

  const District({
    required this.slug,
    required this.name,
    required this.stopCount,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      stopCount: json['stopCount'] is int ? json['stopCount'] as int : int.tryParse(json['stopCount']?.toString() ?? '0') ?? 0,
    );
  }
}

class BusStop {
  final String id;
  final String name;
  final String namePa;
  final String nameHi;
  final String city;
  final String state;
  final String country;
  final LatLng position;
  final String? type;
  final bool? publicTransport;
  final bool? shelter;

  const BusStop({
    required this.id,
    required this.name,
    this.namePa = '',
    this.nameHi = '',
    this.city = '',
    this.state = '',
    this.country = 'India',
    required this.position,
    this.type,
    this.publicTransport,
    this.shelter,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    final lat = json['latitude'] ?? json['lat'];
    final lng = json['longitude'] ?? json['lng'];
    return BusStop(
      id: json['id']?.toString() ?? json['stop_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['stop_name']?.toString() ?? 'Bus Stop',
      namePa: json['namePa']?.toString() ?? '',
      nameHi: json['nameHi']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      position: LatLng(
        (lat as num?)?.toDouble() ?? 0.0,
        (lng as num?)?.toDouble() ?? 0.0,
      ),
      type: json['type']?.toString(),
      publicTransport: json['publicTransport'] as bool?,
      shelter: json['shelter'] as bool?,
    );
  }

  String getLocalizedName(String langCode) {
    if (langCode == 'pa') return namePa.isNotEmpty ? namePa : name;
    if (langCode == 'hi') return nameHi.isNotEmpty ? nameHi : name;
    return name;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusStop &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'namePa': namePa,
      'nameHi': nameHi,
      'city': city,
      'state': state,
      'country': country,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'type': type,
      'publicTransport': publicTransport,
      'shelter': shelter,
    };
  }

  BusStop copyWith({
    String? id,
    String? name,
    String? namePa,
    String? nameHi,
    String? city,
    String? state,
    String? country,
    LatLng? position,
    String? type,
    bool? publicTransport,
    bool? shelter,
  }) {
    return BusStop(
      id: id ?? this.id,
      name: name ?? this.name,
      namePa: namePa ?? this.namePa,
      nameHi: nameHi ?? this.nameHi,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      position: position ?? this.position,
      type: type ?? this.type,
      publicTransport: publicTransport ?? this.publicTransport,
      shelter: shelter ?? this.shelter,
    );
  }
}