import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationHistoryModel {
  String reminderId; // Links to the reminder in the "reminder" collection
  String medicationName;
  Timestamp timestamp;
  bool taken; 
  MedicationHistoryModel({
    required this.reminderId,
    required this.medicationName,
    required this.timestamp,
    required this.taken,
  });

  Map<String, dynamic> toMap() {
    return {
      'reminderId': reminderId,
      'medicationName': medicationName,
      'timestamp': timestamp,
      'taken': taken,
    };
  }

  factory MedicationHistoryModel.fromMap(Map<String, dynamic> map) {
    return MedicationHistoryModel(
      reminderId: map['reminderId'],
      medicationName: map['medicationName'],
      timestamp: map['timestamp'],
      taken: map['taken'],
    );
  }
}