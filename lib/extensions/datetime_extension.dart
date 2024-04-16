import 'package:jiffy/jiffy.dart';

extension DateTimeExtension on DateTime {
  String formateDateTime(String format) {
    return Jiffy.parseFromDateTime(this).format(pattern: format).toString();
  }
}