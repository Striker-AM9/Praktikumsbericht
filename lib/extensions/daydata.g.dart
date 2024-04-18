// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daydata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DayData _$DayDataFromJson(Map<String, dynamic> json) => DayData(
      date: json['date'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      tasks: json['tasks'] as String,
    );

Map<String, dynamic> _$DayDataToJson(DayData instance) => <String, dynamic>{
      'date': instance.date,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'tasks': instance.tasks,
    };
