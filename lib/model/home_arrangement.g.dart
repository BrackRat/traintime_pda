// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_arrangement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeArrangement _$HomeArrangementFromJson(Map<String, dynamic> json) =>
    HomeArrangement(
      name: json['name'] as String,
      teacher: json['teacher'] as String?,
      place: json['place'] as String?,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );

Map<String, dynamic> _$HomeArrangementToJson(HomeArrangement instance) =>
    <String, dynamic>{
      'name': instance.name,
      'teacher': instance.teacher,
      'place': instance.place,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
    };
