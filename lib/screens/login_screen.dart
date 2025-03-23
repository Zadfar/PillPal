import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mm_project/screens/profile_center_screen.dart';
import 'package:mm_project/screens/signup_screen.dart';
import 'package:mm_project/utils/app_colors.dart';
import 'package:mm_project/widgets/round_gradient_button.dart';
import 'package:mm_project/widgets/round_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isObscure = true;
  final _formkey = GlobalKey<FormState>();

  Future<User?> _signin(
    BuildContext context, String email, String password) async {
      try{
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);

        User? user = userCredential.user;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login successful")
            ),
        );

        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileCenterScreen(),));
        return user;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed, Please check your email and password")
            ),
        );
        return null;
      }
    }

  @override
  void initState() {
    // TODO: implement initState
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
          padding: EdgeInsets.symmetric(vertical: 25, horizontal: 25),
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
                      SizedBox(height: media.width * 0.03,
                      ),
                      Text("Hey There",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      ),
                    SizedBox(height: media.width * 0.01,
                      ),
                      Text("Welcome Back",
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
                SizedBox(
                  height: media.width * 0.1,
                ),
                RoundTextField(
                  textEditingController: _emailController,
                  hintText: "Email",
                  icon: "assets/icons/mail.png",
                  textinputType: TextInputType.emailAddress,
                  validator: (value) {
                    if(value == null || value.isEmpty) {
                      return "Please enter your email";
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                RoundTextField(
                  textEditingController: _passController,
                  hintText: "Password",
                  icon: "assets/icons/unlock.png",
                  textinputType: TextInputType.text,
                  isObscureText: _isObscure,
                  validator: (value) {
                    if(value == null || value.isEmpty) {
                      return "Please enter your password";
                    } else if (value.length < 6) {
                      return "Password must be atleast 6 characters long";
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: (){},
                    child: Text(
                      "Forgot your password?",
                      style: TextStyle(
                        color: AppColors.secondaryColor1,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      ),
                    ),
                ),
                SizedBox(
                  height: media.width * 0.1,
                ),
                RoundGradientButton(title: "Login", 
                onPressed: () {
                  if (_formkey.currentState!.validate()) {
                    _signin(context, _emailController.text, _passController.text);
                  }
                }),

                SizedBox(
                  height: media.width * 0.01,
                ),
                Row(
                  children: [
                    Expanded(child: Container(
                      width: double.maxFinite,
                      height: 1,
                      color: AppColors.grayColor.withOpacity(0.5),
                    ),
                    ),
                    Text(" Or ",
                    style: TextStyle(
                      color: AppColors.grayColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    ),
                    Expanded(child: Container(
                      width: double.maxFinite,
                      height: 1,
                      color: AppColors.grayColor.withOpacity(0.5),
                    ),
                    ),
                  ], 
                ),
                SizedBox(
                  height: media.width * 0.05,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: (){},
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
                          child: Image.asset("assets/icons/google.png",
                          height: 20, width: 20,),
                        ),
                      ),
                      SizedBox(width: 30,),
                      GestureDetector(
                        onTap: (){},
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
                          child: Image.asset("assets/icons/facebook.png",
                          height: 25, width: 25,),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                  height: media.width * 0.05,
                  ),
                  TextButton(onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen(),));
                  },
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(text: "Don't have an account?  "),
                        TextSpan(
                          text: "Register",
                          style: TextStyle(
                            color: AppColors.secondaryColor1,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ]
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