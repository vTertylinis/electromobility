import 'dart:convert';


class Evsebill {
  final String? serial;
  final String? start;
  final String? end;
  final int? hours;
  final double? minutes;
  final String? chargingPoint;
  final double value;
  final double vat;
  final double total;
  final int? energy;
 const Evsebill({
    required this.serial,
    required this.start,
    required this.end,
    required this.hours,
    required this.minutes,
    required this.chargingPoint,
    required this.value,
    required this.vat,
    required this.total,
    required this.energy
  });
  factory Evsebill.fromJson(Map<String, dynamic> json) {
    return Evsebill(
      serial: json['serial'] as String?,
      start: json['start'] as String?,
      end: json['end'] as String?,
      hours: json['hours'] as int?,
      minutes: json['minutes'] as double?,
      chargingPoint: json['chargingPoint'] as String?,
      value: json['value']as double,
      vat: json['vat']as double,
      total: json['total']as double,
      energy: json['energy']as int?,
    );
  }
}class Evsebillall {
  final String firstName;
  final String lastName;
  final int userID;
  final int month;
  final int year;

 const Evsebillall({
    required this.firstName,
    required this.lastName,
    required this.userID,
    required this.month,
    required this.year
  });
  factory Evsebillall.fromJson(Map<String, dynamic> json) {
    return Evsebillall(
      firstName: json['firstName'] as String,
      lastName: json['lastName']as String,
      userID: json['userID']as int,
      month: json['month']as int,
      year: json['year']as int,
    );
  }
}