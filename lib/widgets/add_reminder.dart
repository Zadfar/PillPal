import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mm_project/model/reminder_model.dart';
import 'package:mm_project/services/notification_logic.dart';
import 'package:mm_project/utils/app_colors.dart';
import 'package:mm_project/widgets/round_text_field.dart';

Future<void> addReminder(BuildContext context, String uid) {
  final TextEditingController _medNameController = TextEditingController();
  TimeOfDay? selectedTime = TimeOfDay.now();
  String frequency = 'Daily'; // Default frequency
  int intervalHours = 1; // Default interval in hours

  void add(String uid, TimeOfDay time, String freq, int interval) async {
    try {
      DateTime now = DateTime.now();
      DateTime dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (dateTime.isBefore(now)) {
        dateTime = dateTime.add(const Duration(days: 1));
      }
      Timestamp timestamp = Timestamp.fromDate(dateTime);

      ReminderModel reminderModel = ReminderModel(medicationName: _medNameController.text);
      reminderModel.timestamp = timestamp;
      reminderModel.onOff = true; // Start as active
      reminderModel.frequency = freq; // Add frequency to model
      reminderModel.intervalHours = interval; // Add interval to model

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reminder')
          .add(reminderModel.toMap());

      // Schedule notification
      await NotificationLogic.showNotifications(
        id: docRef.id.hashCode, // Unique ID based on document ID
        title: "PillPal",
        body: "Time to take ${_medNameController.text}",
        dateTime: dateTime,
      );

      Fluttertoast.showToast(msg: "Reminder Added");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to add reminder: $e");
    }
  }

  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            backgroundColor: AppColors.whiteColor,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      "Add New Reminder",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Medication Name
                    const Text(
                      "Medication Name",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grayColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RoundTextField(
                      textEditingController: _medNameController,
                      hintText: "Enter medication name",
                      icon: "assets/icons/pill.png",
                      textinputType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a medication name";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Time Picker
                    const Text(
                      "Reminder Time",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grayColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        TimeOfDay? newTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primaryColor1,
                                  onPrimary: Colors.white,
                                  surface: AppColors.lightGrayColor,
                                ),
                                buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (newTime != null) {
                          setState(() {
                            selectedTime = newTime;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrayColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.clock,
                              color: AppColors.primaryColor1,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedTime?.format(context) ?? "Select Time",
                              style: const TextStyle(
                                fontSize: 18,
                                color: AppColors.blackColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Frequency Dropdown
                    const Text(
                      "Frequency",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grayColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: frequency,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.lightGrayColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: ['Daily', 'Weekly']
                          .map((String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          frequency = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Interval Picker
                    const Text(
                      "Interval Between Doses (Hours)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grayColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: intervalHours,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.lightGrayColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: List.generate(24, (index) => index + 1)
                          .map((int value) => DropdownMenuItem<int>(
                                value: value,
                                child: Text("$value hour${value > 1 ? 's' : ''}"),
                              ))
                          .toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          intervalHours = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 30),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: AppColors.grayColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_medNameController.text.isNotEmpty && selectedTime != null) {
                              add(uid, selectedTime!, frequency, intervalHours);
                              Navigator.pop(context);
                            } else {
                              Fluttertoast.showToast(msg: "Please fill all required fields");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text(
                            "Add Reminder",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}