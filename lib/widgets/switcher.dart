import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class Switcher extends StatefulWidget {
  bool onOff;
  String uid;
  String id;
  Timestamp timestamp;
  String medName;

  Switcher(this.onOff, this.uid, this.id, this.timestamp, this.medName);

  @override
  State<Switcher> createState() => _SwitcherState();
}

class _SwitcherState extends State<Switcher> {
  @override
  Widget build(BuildContext context) {
    return Switch(
      value: widget.onOff,
      onChanged: (bool value) {
        // Update only the 'onOff' field in Firestore
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .collection("reminder")
            .doc(widget.id)
            .update({'onOff': value}).then((_) {
          setState(() {
            widget.onOff = value; // Update local state
          });
        }).catchError((error) {
          print("Failed to update reminder: $error");
        });
      },
    );
  }
}