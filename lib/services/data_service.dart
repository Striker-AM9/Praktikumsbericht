import 'dart:convert';

import 'package:praktikumsbericht/extensions/daydata.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataService {
  final SharedPreferences sharedPreferences;
  DataService(this.sharedPreferences);

  static const _storageKey = 'report';

  Future<bool> storeData(DayData dayData) async {
    Map<String, dynamic> dayDataMap = dayData.toJson();

    String? data = sharedPreferences.getString(_storageKey);
    String encodedDayDataList = '';
    if (data == null) {
      encodedDayDataList = jsonEncode([dayDataMap]);
    } else {
      List<Map<String, dynamic>> dayDataList =
          List<Map<String, dynamic>>.from(jsonDecode(data));
      dayDataList.add(dayDataMap);
      dayDataList.sort((a, b) => a['date'].compareTo(b['date']));
      encodedDayDataList = jsonEncode(dayDataList);
    }
    return await sharedPreferences.setString(_storageKey, encodedDayDataList);
  }

  Future<bool> updateData(DayData dayData) async {
    List<DayData> data = await getData();
    data = data.map((e) {
      if (e == dayData) {
        return dayData;
      } else {
        return e;
      }
    }).toList();
    return await sharedPreferences.setString(_storageKey, jsonEncode(data));
  }

  Future<List<DayData>> getData() async {
    String? data = sharedPreferences.getString(_storageKey);
    if (data == null) {
      return [];
    } else {
      List<Map<String, dynamic>> dayDataList =
          List<Map<String, dynamic>>.from(jsonDecode(data));
      return dayDataList.map((e) => DayData.fromJson(e)).toList();
    }
  }

  Future<bool> deletaData(DayData dayData) async {
    List<DayData> data = await getData();
    data = data.where((element) {
      if (element != dayData) {
        return true;
      } else {
        return false;
      }
    }).toList();
    return await sharedPreferences.setString(_storageKey, jsonEncode(data));
  }
}
