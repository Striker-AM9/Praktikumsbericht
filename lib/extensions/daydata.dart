import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'daydata.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class DayData extends Equatable {
  final String date;
  final String startTime;
  final String endTime;
  final String tasks;

  const DayData(
      {required this.date,
        required this.startTime,
        required this.endTime,
        required this.tasks});

  @override
  List<Object?> get props => [date];

  factory DayData.fromJson(Map<String, dynamic> json) =>
      _$DayDataFromJson(json);
  Map<String, dynamic> toJson() => _$DayDataToJson(this);
}