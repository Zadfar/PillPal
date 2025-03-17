import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  String medicationName;
  Timestamp? timestamp;
  bool? onOff;
  String? frequency;
  int? intervalHours;
  List<int>? notificationIds;
  int? totalPills;
  int? pillsPerDose;
  int? refillNotificationId;

  ReminderModel({required this.medicationName, this.timestamp, this.onOff, this.frequency, this.intervalHours, this.notificationIds, this.totalPills, this.pillsPerDose, this.refillNotificationId});

  Map<String, dynamic> toMap() {
    return {
      'name': medicationName,
      'time': timestamp,
      'onOff': onOff,
      'frequency': frequency,
      'intervalHours': intervalHours,
      'notificationIds': notificationIds,
      'totalPills': totalPills,
      'pillsPerDose': pillsPerDose,
      'refillNotificationId': refillNotificationId,
    };
  }
  factory ReminderModel.fromMap(map){
    return ReminderModel(medicationName: map['name'], timestamp: map['time'], onOff: map['onOff'], frequency: map['frequency'], intervalHours: map['intervalHours'], notificationIds: map['notificationIds']?.cast<int>(), totalPills: map['totalPills'], pillsPerDose: map['pillsPerDose'], refillNotificationId: map['refillNotificationId'],);
  }
}