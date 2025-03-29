import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mm_project/services/notification_logic.dart';

deleteReminder(BuildContext context, String id, String uid, String profileId) {
  return showDialog(context: context,
   builder: (context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      title: Text("Delete Reminder"),
      content: Text("Are you sure you want to delete?"),
      actions: [
        TextButton(onPressed: () async {
          try {
            DocumentSnapshot reminderDoc = await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection('profiles')
              .doc(profileId)
              .collection("reminder")
              .doc(id)
              .get();

            List<dynamic>? notificationIds = reminderDoc.get('notificationIds');
            
            if (notificationIds != null && notificationIds.isNotEmpty) {
              List<int> ids = notificationIds.cast<int>();
              await NotificationLogic.cancelSpecificNotifications(ids);
            }

            await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection('profiles')
              .doc(profileId)
              .collection("reminder")
              .doc(id)
              .delete();
            Fluttertoast.showToast(msg: "Reminder Deleted");
          } catch (e) {
            Fluttertoast.showToast(msg: e.toString());
          }
          Navigator.pop(context);
        },
        child: Text("Delete"),
        ),
        TextButton(onPressed: () {
          Navigator.pop(context);
        },
        child: Text("Cancel"),
        ),
      ],
    );
   },);
}