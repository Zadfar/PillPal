import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  String medicationName;
  Timestamp? timestamp;
  bool? onOff;

  ReminderModel({required this.medicationName, this.timestamp, this.onOff});

  Map<String, dynamic> toMap() {
    return {
      'name': medicationName,
      'time': timestamp,
      'onOff': onOff,
    };
  }
  factory ReminderModel.fromMap(map){
    return ReminderModel(medicationName: map['name'], timestamp: map['time'], onOff: map['onOff'],);
  }
}