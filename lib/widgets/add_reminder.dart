import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mm_project/model/reminder_model.dart';
import 'package:mm_project/services/notification_logic.dart';
import 'package:mm_project/utils/app_colors.dart';
import 'package:mm_project/widgets/round_text_field.dart';
import 'dart:io';

Future<void> addReminder(BuildContext context, String uid, String profileId) {
  final TextEditingController _medNameController = TextEditingController();
  final TextEditingController _totalPillsController = TextEditingController();
  final TextEditingController _pillsPerDoseController = TextEditingController();
  TimeOfDay? selectedTime = TimeOfDay.now();
  String frequency = 'Daily';
  int intervalHours = 1;
  File _selectedImage;

  Future<void> _extractTextFromImage(File imageFile) async {
    try {
      Fluttertoast.showToast(msg: "Processing image...");
      
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String extractedText = recognizedText.text;
      textRecognizer.close();
      
      if (extractedText.isNotEmpty) {
        String? possibleMedName = extractedText.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .firstWhere((line) => line.length > 3, orElse: () => '');
        
        if (possibleMedName.isNotEmpty) {
          _medNameController.text = possibleMedName;
          Fluttertoast.showToast(msg: "Text extracted successfully");
        } else {
          Fluttertoast.showToast(msg: "No recognizable text found");
        }
      } else {
        Fluttertoast.showToast(msg: "No text found in image");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to extract text: $e");
    }
  }

   Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        await _extractTextFromImage(_selectedImage);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to pick image: $e");
    }
  }

  void add(String uid, TimeOfDay time, String freq, int interval) async {
    try {
      DateTime now = DateTime.now();
      DateTime dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (dateTime.isBefore(now)) {
        dateTime = dateTime.add(const Duration(days: 1));
      }
      Timestamp timestamp = Timestamp.fromDate(dateTime);

      int totalPills = int.parse(_totalPillsController.text);
      int pillsPerDose = int.parse(_pillsPerDoseController.text);
      int dosesPerDay = freq == 'Daily' ? (24 ~/ interval) : (24 ~/ (interval * 7));
      int daysUntilRefill = (totalPills ~/ (pillsPerDose * dosesPerDay));
      DateTime refillDate = now.add(Duration(days: daysUntilRefill - 2));
      int refillNotificationId = "${dateTime.millisecondsSinceEpoch}_refill".hashCode;

      ReminderModel reminderModel = ReminderModel(medicationName: _medNameController.text);
      reminderModel.timestamp = timestamp;
      reminderModel.onOff = true;
      reminderModel.frequency = freq;
      reminderModel.intervalHours = interval;
      reminderModel.totalPills = totalPills;
      reminderModel.pillsPerDose = pillsPerDose;
      reminderModel.refillNotificationId = refillNotificationId;

      int reminderId = "${uid}_${_medNameController.text}_${dateTime.millisecondsSinceEpoch}".hashCode;
      reminderModel.notificationIds = [reminderId];

      await NotificationLogic.scheduleRecurringNotification(
        id: reminderId,
        title: "PillPal",
        body: "Time to take ${_medNameController.text}",
        payload: "$profileId|$reminderId",
        startTime: dateTime,
        frequency: freq,
        intervalHours: interval,
      );

      // Schedule refill notification
      await NotificationLogic.showNotification(
        id: refillNotificationId,
        title: "PillPal Refill Reminder",
        body: "Time to refill ${_medNameController.text}! Only a few days left.",
        payload: "$profileId|refill",
        dateTime: refillDate,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('profiles')
          .doc(profileId)
          .collection('reminder')
          .add(reminderModel.toMap());

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
                    const Text(
                      "Add New Reminder",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Medication Name", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.grayColor)),
                    const SizedBox(height: 8),
                    RoundTextField(
                      textEditingController: _medNameController,
                      hintText: "Enter medication name",
                      icon: "assets/icons/pill.png",
                      textinputType: TextInputType.text,
                      validator: (value) => value == null || value.isEmpty ? "Please enter a medication name" : null,
                    ),
                    const SizedBox(height: 20),
                    const Text("Or", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.grayColor)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await _pickImage();
                        setState(() {});
                      }, 
                      child: Text("Use Image")
                    ),
                    const SizedBox(height: 20),
                    const Text("Reminder Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.grayColor)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        TimeOfDay? newTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                          builder: (context, child) => Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(primary: AppColors.primaryColor1, onPrimary: Colors.white, surface: AppColors.lightGrayColor),
                              buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                            ),
                            child: child!,
                          ),
                        );
                        if (newTime != null) setState(() => selectedTime = newTime);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(color: AppColors.lightGrayColor, borderRadius: BorderRadius.circular(15)),
                        child: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.clock, color: AppColors.primaryColor1, size: 24),
                            const SizedBox(width: 12),
                            Text(selectedTime?.format(context) ?? "Select Time", style: const TextStyle(fontSize: 18, color: AppColors.blackColor, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Frequency", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.grayColor)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: frequency,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.lightGrayColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: ['Daily', 'Weekly'].map((value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                      onChanged: (newValue) => setState(() => frequency = newValue!),
                    ),
                    const SizedBox(height: 20),
                    const Text("Interval Between Doses (Hours)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.grayColor)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: intervalHours,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.lightGrayColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: List.generate(24, (index) => index + 1)
                          .map((value) => DropdownMenuItem<int>(value: value, child: Text("$value hour${value > 1 ? 's' : ''}")))
                          .toList(),
                      onChanged: (newValue) => setState(() => intervalHours = newValue!),
                    ),
                    const SizedBox(height: 20),
                    const Text("Total Pills", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.grayColor)),
                    const SizedBox(height: 8),
                    RoundTextField(
                      textEditingController: _totalPillsController,
                      hintText: "Enter total pills",
                      icon: "assets/icons/pill.png",
                      textinputType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty || int.tryParse(value) == null ? "Please enter a valid number" : null,
                    ),
                    const SizedBox(height: 20),
                    const Text("Pills Per Dose", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.grayColor)),
                    const SizedBox(height: 8),
                    RoundTextField(
                      textEditingController: _pillsPerDoseController,
                      hintText: "Enter pills per dose",
                      icon: "assets/icons/pill.png",
                      textinputType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty || int.tryParse(value) == null ? "Please enter a valid number" : null,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel", style: TextStyle(color: AppColors.grayColor, fontSize: 16, fontWeight: FontWeight.w500)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_medNameController.text.isNotEmpty &&
                                selectedTime != null &&
                                _totalPillsController.text.isNotEmpty &&
                                _pillsPerDoseController.text.isNotEmpty) {
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
                          child: const Text("Add Reminder", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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