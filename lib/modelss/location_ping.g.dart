// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_ping.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationPingAdapter extends TypeAdapter<LocationPing> {
  @override
  final int typeId = 0;

  @override
  LocationPing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationPing(
      busId: fields[0] as String,
      routeId: fields[1] as String,
      lat: fields[2] as double,
      lng: fields[3] as double,
      speed: fields[4] as double,
      bearing: fields[5] as double,
      timestamp: fields[6] as DateTime,
      synced: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LocationPing obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.busId)
      ..writeByte(1)
      ..write(obj.routeId)
      ..writeByte(2)
      ..write(obj.lat)
      ..writeByte(3)
      ..write(obj.lng)
      ..writeByte(4)
      ..write(obj.speed)
      ..writeByte(5)
      ..write(obj.bearing)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationPingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
