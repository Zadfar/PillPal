import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  String medicationName;
  Timestamp? timestamp;
  bool? onOff;
  String? frequency;
  int? intervalHours;

  ReminderModel({required this.medicationName, this.timestamp, this.onOff, this.frequency, this.intervalHours});

  Map<String, dynamic> toMap() {
    return {
      'name': medicationName,
      'time': timestamp,
      'onOff': onOff,
      'frequency': frequency,
      'intervalHours': intervalHours,
    };
  }
  factory ReminderModel.fromMap(map){
    return ReminderModel(medicationName: map['name'], timestamp: map['time'], onOff: map['onOff'], frequency: map['frequency'], intervalHours: map['intervalHours']);
  }
}