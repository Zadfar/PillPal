import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mm_project/screens/login_screen.dart';
import 'package:mm_project/screens/profile_setup_screen.dart'; // New import
import 'package:mm_project/utils/app_colors.dart';
import 'package:mm_project/widgets/round_gradient_button.dart';
import 'package:mm_project/widgets/round_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CollectionReference _users = FirebaseFirestore.instance.collection("users");

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isObscure = true;
  bool _isCheck = false;
  final _formkey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
            child: Form(
              key: _formkey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: media.height * 0.1),
                  SizedBox(
                    width: media.width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: media.width * 0.03),
                        const Text(
                          "Hey There",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.blackColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: media.width * 0.01),
                        const Text(
                          "Create an Account",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.blackColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: media.width * 0.02),
                  RoundTextField(
                    textEditingController: _fullNameController,
                    hintText: "Full Name",
                    icon: "assets/icons/user.png",
                    textinputType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your First Name";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: media.width * 0.02),
                  RoundTextField(
                    textEditingController: _emailController,
                    hintText: "Email",
                    icon: "assets/icons/mail.png",
                    textinputType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your Email";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: media.width * 0.02),
                  RoundTextField(
                    textEditingController: _passController,
                    hintText: "Password",
                    icon: "assets/icons/unlock.png",
                    textinputType: TextInputType.text,
                    isObscureText: _isObscure,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your password";
                      } else if (value.length < 6) {
                        return "Password must be at least 6 characters long";
                      }
                      return null;
                    },
                    rightIcon: TextButton(
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 20,
                        width: 20,
                        child: Image.asset(
                          _isObscure ? "assets/icons/show.png" : "assets/icons/hide.png",
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          color: AppColors.grayColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: media.width * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isCheck = !_isCheck;
                          });
                        },
                        icon: Icon(
                          _isCheck ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                          color: AppColors.grayColor,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          "By continuing you accept our Privacy Policy and \nterms of Use",
                          style: TextStyle(
                            color: AppColors.grayColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: media.width * 0.02),
                  RoundGradientButton(
                    title: "Signup",
                    onPressed: () async {
                      if (_formkey.currentState!.validate()) {
                        if (_isCheck) {
                          try {
                            UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
                              email: _emailController.text,
                              password: _passController.text,
                            );
                            String uid = userCredential.user!.uid;

                            // Create initial user document
                            await _users.doc(uid).set({
                              'email': _emailController.text,
                              'fullName': _fullNameController.text,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Account created successfully!")),
                            );

                            // Navigate to ProfileSetupScreen instead of LoginScreen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileSetupScreen(),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please accept the terms and conditions")),
                          );
                        }
                      }
                    },
                  ),
                  SizedBox(height: media.width * 0.01),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.maxFinite,
                          height: 1,
                          color: AppColors.grayColor.withOpacity(0.5),
                        ),
                      ),
                      const Text(
                        " Or ",
                        style: TextStyle(
                          color: AppColors.grayColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: double.maxFinite,
                          height: 1,
                          color: AppColors.grayColor.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: media.width * 0.05),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 50,
                          width: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primaryColor1,
                              width: 1,
                            ),
                          ),
                          child: Image.asset(
                            "assets/icons/google.png",
                            height: 20,
                            width: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 50,
                          width: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primaryColor1,
                              width: 1,
                            ),
                          ),
                          child: Image.asset(
                            "assets/icons/facebook.png",
                            height: 25,
                            width: 25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: media.width * 0.05),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(text: "Already have an account?  "),
                          TextSpan(
                            text: "Login",
                            style: TextStyle(
                              color: AppColors.secondaryColor1,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}