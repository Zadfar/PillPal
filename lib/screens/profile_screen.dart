import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mm_project/utils/app_colors.dart';

class ProfileModel {
  String fullName;
  String age;
  String gender;
  String location;
  String bloodType;
  String allergies;
  String medications;
  String emergencyContact;
  String memberSince;

  ProfileModel({
    this.fullName = 'Unnamed Profile',
    this.age = '',
    this.gender = '',
    this.location = '',
    this.bloodType = '',
    this.allergies = '',
    this.medications = '',
    this.emergencyContact = '',
    this.memberSince = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'location': location,
      'bloodType': bloodType,
      'allergies': allergies,
      'medications': medications,
      'emergencyContact': emergencyContact,
      'memberSince': memberSince,
    };
  }

  factory ProfileModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProfileModel(
      fullName: data['fullName'] ?? 'Unnamed Profile',
      age: data['age'] ?? '',
      gender: data['gender'] ?? '',
      location: data['location'] ?? '',
      bloodType: data['bloodType'] ?? '',
      allergies: data['allergies'] ?? '',
      medications: data['medications'] ?? '',
      emergencyContact: data['emergencyContact'] ?? '',
      memberSince: data['memberSince'] ?? '',
    );
  }
}

class ProfilePage extends StatefulWidget {
  final String profileId;
  const ProfilePage({Key? key, required this.profileId}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _isLoading = true;
  late ProfileModel _profile;
  final _formKey = GlobalKey<FormState>();
  String? _selectedGender;
  String? _selectedBloodType;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;
  late TextEditingController _emergencyContactController;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _profile = ProfileModel();
    _initControllers();
    _loadProfileData();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _profile.fullName);
    _ageController = TextEditingController(text: _profile.age);
    _locationController = TextEditingController(text: _profile.location);
    _allergiesController = TextEditingController(text: _profile.allergies);
    _medicationsController = TextEditingController(text: _profile.medications);
    _emergencyContactController = TextEditingController(text: _profile.emergencyContact);
  }

  void _updateControllers() {
    _nameController.text = _profile.fullName;
    _ageController.text = _profile.age;
    _selectedGender = _profile.gender.isNotEmpty ? _profile.gender : null;
    _locationController.text = _profile.location;
    _selectedBloodType = _profile.bloodType.isNotEmpty ? _profile.bloodType : null;
    _allergiesController.text = _profile.allergies;
    _medicationsController.text = _profile.medications;
    _emergencyContactController.text = _profile.emergencyContact;
  }

  Future<void> _loadProfileData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('profiles')
            .doc(widget.profileId)
            .get();

        if (snapshot.exists) {
          setState(() {
            _profile = ProfileModel.fromFirestore(snapshot);
            _updateControllers();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile not found')),
          );
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _saveProfileData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        _profile = ProfileModel(
          fullName: _nameController.text,
          age: _ageController.text,
          gender: _selectedGender ?? '',
          location: _locationController.text,
          bloodType: _selectedBloodType ?? '',
          allergies: _allergiesController.text,
          medications: _medicationsController.text,
          emergencyContact: _emergencyContactController.text,
          memberSince: _profile.memberSince.isEmpty ? DateTime.now().year.toString() : _profile.memberSince,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('profiles')
            .doc(widget.profileId)
            .set(_profile.toJson(), SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrayColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'Profile'),
        backgroundColor: AppColors.secondaryColor2,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                if (_formKey.currentState!.validate()) {
                  _saveProfileData().then((_) {
                    setState(() {
                      _isEditing = false;
                    });
                  });
                }
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _updateControllers();
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.whiteColor,
                            child: Icon(Icons.person, size: 60, color: AppColors.grayColor),
                          ),
                          const SizedBox(height: 12),
                          _isEditing
                              ? TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blackColor,
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.whiteColor)),
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.whiteColor)),
                                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.whiteColor)),
                                  ),
                                  validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                                )
                              : Text(
                                  _profile.fullName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blackColor,
                                  ),
                                ),
                          const SizedBox(height: 4),
                          Text(
                            'Member since ${_profile.memberSince.isEmpty ? 'N/A' : _profile.memberSince}',
                            style: TextStyle(
                              color: AppColors.blackColor.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoSection('Personal Information', [
                      _buildEditableField(
                        icon: Icons.cake,
                        label: 'Age',
                        controller: _ageController,
                        isEditing: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your age';
                          if (int.tryParse(value) == null) return 'Please enter a valid number';
                          return null;
                        },
                        keyboardType: TextInputType.number,
                      ),
                      _buildEditableDropdown(
                        icon: Icons.person_outline,
                        label: 'Gender',
                        value: _selectedGender,
                        items: _genderOptions,
                        isEditing: _isEditing,
                        onChanged: (value) => setState(() => _selectedGender = value),
                        validator: (value) => value == null ? 'Please select your gender' : null,
                      ),
                      _buildEditableField(
                        icon: Icons.location_on,
                        label: 'Location',
                        controller: _locationController,
                        isEditing: _isEditing,
                        validator: (value) => value == null || value.isEmpty ? 'Please enter your location' : null,
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildInfoSection('Health Information', [
                      _buildEditableDropdown(
                        icon: Icons.medical_services,
                        label: 'Blood Type',
                        value: _selectedBloodType,
                        items: _bloodTypes,
                        isEditing: _isEditing,
                        onChanged: (value) => setState(() => _selectedBloodType = value),
                        validator: (value) => value == null ? 'Please select your blood type' : null,
                      ),
                      _buildEditableField(
                        icon: Icons.warning_amber,
                        label: 'Allergies',
                        controller: _allergiesController,
                        isEditing: _isEditing,
                        maxLines: 3,
                      ),
                      _buildEditableField(
                        icon: Icons.medication,
                        label: 'Medications',
                        controller: _medicationsController,
                        isEditing: _isEditing,
                        maxLines: 3,
                      ),
                      _buildEditableField(
                        icon: Icons.emoji_people,
                        label: 'Emergency Contact',
                        controller: _emergencyContactController,
                        isEditing: _isEditing,
                        validator: (value) {
                          if(value == null || value.isEmpty) {
                            return "Please Enter an Emergency Number";
                          }
                          if(!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return "Please Enter a Valid 10-digit Phone Number";
                          }
                          return null;
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.blackColor),
            ),
          ),
          const Divider(height: 1, color: AppColors.lightGrayColor),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor1, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 4),
                isEditing
                    ? TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: validator,
                        keyboardType: keyboardType,
                        maxLines: maxLines,
                      )
                    : Text(
                        controller.text.isEmpty ? 'Not set' : controller.text,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.blackColor),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDropdown({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    required bool isEditing,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor1, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 4),
                isEditing
                    ? DropdownButtonFormField<String>(
                        value: value,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                        onChanged: onChanged,
                        validator: validator,
                      )
                    : Text(
                        value ?? 'Not set',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.blackColor),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}