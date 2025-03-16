import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mm_project/screens/home_screen.dart';
import 'package:mm_project/utils/app_colors.dart';
import 'package:mm_project/widgets/round_gradient_button.dart';
import 'package:mm_project/widgets/round_text_field.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _users = FirebaseFirestore.instance.collection('users');

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final User? user = _auth.currentUser;
        if (user != null) {
          await _users.doc(user.uid).update({
            'age': _ageController.text,
            'gender': _genderController.text,
            'location': _locationController.text,
            'bloodType': _bloodTypeController.text,
            'allergies': _allergiesController.text,
            'medications': _medicationsController.text,
            'emergencyContact': _emergencyContactController.text,
            'memberSince': DateTime.now().year.toString(), // Example value
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile setup complete!')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
        backgroundColor: AppColors.secondaryColor2,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Let’s get to know you!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 20),
                RoundTextField(
                  textEditingController: _ageController,
                  hintText: "Age",
                  icon: "assets/icons/cake.png",
                  textinputType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter your age";
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                RoundTextField(
                  textEditingController: _genderController,
                  hintText: "Gender",
                  icon: "assets/icons/gender.png",
                  textinputType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter your gender";
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                RoundTextField(
                  textEditingController: _locationController,
                  hintText: "Location",
                  icon: "assets/icons/location.png",
                  textinputType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter your location";
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                RoundTextField(
                  textEditingController: _bloodTypeController,
                  hintText: "Blood Type",
                  icon: "assets/icons/blood.png",
                  textinputType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter your blood type";
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                RoundTextField(
                  textEditingController: _allergiesController,
                  hintText: "Allergies (optional)",
                  icon: "assets/icons/allergy.png",
                  textinputType: TextInputType.text,
                ),
                const SizedBox(height: 15),
                RoundTextField(
                  textEditingController: _medicationsController,
                  hintText: "Medications (optional)",
                  icon: "assets/icons/pill.png",
                  textinputType: TextInputType.text,
                ),
                const SizedBox(height: 15),
                RoundTextField(
                  textEditingController: _emergencyContactController,
                  hintText: "Emergency Contact",
                  icon: "assets/icons/emergency.png",
                  textinputType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter an emergency contact";
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                RoundGradientButton(
                  title: "Save and Continue",
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}