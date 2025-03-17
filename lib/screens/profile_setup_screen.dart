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
  String? _selectedGender;
  final TextEditingController _locationController = TextEditingController();
  String? _selectedBloodType;
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final User? user = _auth.currentUser;
        if (user != null) {
          await _users.doc(user.uid).update({
            'age': _ageController.text,
            'gender': _selectedGender,
            'location': _locationController.text,
            'bloodType': _selectedBloodType,
            'allergies': _allergiesController.text,
            'medications': _medicationsController.text,
            'emergencyContact': _emergencyContactController.text,
            'memberSince': DateTime.now().year.toString(),
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
                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  hint: const Text("Select Gender"),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.lightGrayColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Container(
                      alignment: Alignment.center,
                      width: 20,
                      height: 20,
                      child: Image.asset(
                        "assets/icons/gender.png",
                        height: 20,
                        width: 20,
                        fit: BoxFit.contain,
                        color: AppColors.grayColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _genderOptions
                      .map((String gender) => DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) return "Please select your gender";
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
                // Blood Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedBloodType,
                  hint: const Text("Select Blood Type"),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.lightGrayColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Container(
                      alignment: Alignment.center,
                      width: 20,
                      height: 20,
                      child: Image.asset(
                        "assets/icons/blood.png",
                        height: 20,
                        width: 20,
                        fit: BoxFit.contain,
                        color: AppColors.grayColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _bloodTypes
                      .map((String bloodType) => DropdownMenuItem<String>(
                            value: bloodType,
                            child: Text(bloodType),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedBloodType = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) return "Please select your blood type";
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