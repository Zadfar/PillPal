import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mm_project/model/reminder_model.dart';

// ignore: must_be_immutable
class Switcher extends StatefulWidget {
  bool onOff;
  String uid;
  Timestamp timestamp;
  String id;
  String medName;

  Switcher(this.onOff, this.uid, this.id, this.timestamp, this.medName);

  @override
  State<Switcher> createState() => _SwitcherState();
}

class _SwitcherState extends State<Switcher> {
  @override
  Widget build(BuildContext context) {
    return Switch(
      onChanged: (bool value) {
        ReminderModel reminderModel = ReminderModel(medicationName: widget.medName);
        reminderModel.onOff = value;
        reminderModel.timestamp = widget.timestamp;
        FirebaseFirestore.instance.collection('users').doc(widget.uid).collection("reminder").doc(widget.id).update(reminderModel.toMap());
      },
      value: widget.onOff,);
  }
}