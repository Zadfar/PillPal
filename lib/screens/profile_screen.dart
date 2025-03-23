import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    this.fullName = 'Jane Doe',
    this.age = '32',
    this.gender = 'Female',
    this.location = 'New York, USA',
    this.bloodType = 'A+',
    this.allergies = 'Peanuts, Penicillin',
    this.medications = 'None',
    this.emergencyContact = 'John Doe (555-123-4567)',
    this.memberSince = '2023',
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

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      fullName: json['fullName'] ?? 'Jane Doe',
      age: json['age'] ?? '32',
      gender: json['gender'] ?? 'Female',
      location: json['location'] ?? 'New York, USA',
      bloodType: json['bloodType'] ?? 'A+',
      allergies: json['allergies'] ?? 'Peanuts, Penicillin',
      medications: json['medications'] ?? 'None',
      emergencyContact: json['emergencyContact'] ?? 'John Doe (555-123-4567)',
      memberSince: json['memberSince'] ?? '2023',
    );
  }

  factory ProfileModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProfileModel(
      fullName: data['fullName'] ?? 'Jane Doe',
      age: data['age'] ?? '32',
      gender: data['gender'] ?? 'Female',
      location: data['location'] ?? 'New York, USA',
      bloodType: data['bloodType'] ?? 'A+',
      allergies: data['allergies'] ?? 'Peanuts, Penicillin',
      medications: data['medications'] ?? 'None',
      emergencyContact: data['emergencyContact'] ?? 'John Doe (555-123-4567)',
      memberSince: data['memberSince'] ?? '2023',
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _isLoading = true;
  late ProfileModel _profile;
  final _formKey = GlobalKey<FormState>();
  String? _selectedGender; // Added for dropdown
  String? _selectedBloodType; // Already present
  final List<String> _genderOptions = ['Male', 'Female', 'Other']; // Added gender options
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;
  late TextEditingController _emergencyContactController;

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _profile = ProfileModel();
    _initControllers();
    _loadUserData();
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
    _selectedGender = _profile.gender;
    _locationController.text = _profile.location;
    _selectedBloodType = _profile.bloodType;
    _allergiesController.text = _profile.allergies;
    _medicationsController.text = _profile.medications;
    _emergencyContactController.text = _profile.emergencyContact;
  }

  Future<void> _loadUserData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userId = user.uid;
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _firestore.collection('users').doc(_userId).get();

        if (snapshot.exists) {
          setState(() {
            _profile = ProfileModel.fromFirestore(snapshot);
            _updateControllers();
            _isLoading = false;
          });
        } else {
          _saveUserData();
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    try {
      _profile = ProfileModel(
        fullName: _nameController.text,
        age: _ageController.text,
        gender: _selectedGender ?? _profile.gender,
        location: _locationController.text,
        bloodType: _selectedBloodType ?? _profile.bloodType,
        allergies: _allergiesController.text,
        medications: _medicationsController.text,
        emergencyContact: _emergencyContactController.text,
        memberSince: _profile.memberSince,
      );

      await _firestore.collection('users').doc(_userId).set(_profile.toJson());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
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
                  _saveUserData().then((_) {
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
                            backgroundColor: AppColors.grayColor,
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
                                  decoration: InputDecoration(
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
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
                            'Member since ${_profile.memberSince}',
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
                          if (value == null || value.isEmpty) {
                            return 'Please enter your age';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
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
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Please select your gender';
                          return null;
                        },
                      ),
                      _buildEditableField(
                        icon: Icons.location_on,
                        label: 'Location',
                        controller: _locationController,
                        isEditing: _isEditing,
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
                        onChanged: (value) {
                          setState(() {
                            _selectedBloodType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Please select your blood type';
                          return null;
                        },
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
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(),
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
          Icon(
            icon,
            color: Colors.blue[700],
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                isEditing
                    ? TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        validator: validator,
                        keyboardType: keyboardType,
                        maxLines: maxLines,
                      )
                    : Text(
                        controller.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
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
          Icon(
            icon,
            color: Colors.blue[700],
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                isEditing
                    ? DropdownButtonFormField<String>(
                        value: value,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        items: items
                            .map((item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                ))
                            .toList(),
                        onChanged: onChanged,
                        validator: validator,
                      )
                    : Text(
                        value ?? 'Not set',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}