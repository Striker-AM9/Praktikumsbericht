import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      List<Map<String, dynamic>> dayDataList = List<Map<String, dynamic>>.from(jsonDecode(data));
      dayDataList.add(dayDataMap);
      dayDataList.sort((a, b) => a['date'].compareTo(b['date']));
      encodedDayDataList = jsonEncode([dayDataMap]);
    }
    return await sharedPreferences.setString(_storageKey, encodedDayDataList);
  }

  Future<List<DayData>> getData() async {
    String? data = sharedPreferences.getString(_storageKey);
    if (data == null) {
      return [];
    }
    else {
      List <Map<String, dynamic>> dayDataList = List<Map<String, dynamic>>.from(jsonDecode(data));
      return dayDataList.map((e) => DayData.fromJson(e)).toList();
    }
  }

}
