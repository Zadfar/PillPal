import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mm_project/services/notification_logic.dart';
import 'package:mm_project/utils/app_colors.dart';
import 'package:mm_project/widgets/add_reminder.dart';
import 'package:mm_project/widgets/delete_reminder.dart';
import 'package:mm_project/widgets/switcher.dart';
import 'package:mm_project/screens/profile_screen.dart';
import 'package:mm_project/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  Future<void> _signOut() async {
    if (!mounted) return;

    try {
      await _auth.signOut();

      if (_auth.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed out')),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout incomplete. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign out. Please check your connection and try again.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      });
    } else {
      NotificationLogic.init(context, user!.uid);
      listenNotifications();
    }
  }

  void listenNotifications() {
    NotificationLogic.onNotifications.listen((value) {});
  }

  void onClickedNotifications(String? payload) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.whiteColor,
          centerTitle: true,
          elevation: 0,
          title: const Text(
            "PillPal",
            style: TextStyle(
              color: AppColors.blackColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        drawer: Drawer(
          surfaceTintColor: AppColors.lightGrayColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text(
                  "Profile Centre",
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text(
                  "Settings",
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_outlined),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: _signOut,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          onPressed: () async {
            addReminder(context, user!.uid);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryG,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(100),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(user!.uid)
              .collection("reminder")
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            // Handle loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4FA8C5)),
                ),
              );
            }

            // Check for errors
            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}"),
              );
            }

            // Handle null data or empty collection
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: Text("No data available"),
              );
            }

            // Now safe to check if docs are empty
            if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("Nothing to Show"),
              );
            }

            // Data is available and non-empty
            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.docs.length,
              itemBuilder: (context, index) {
                String medName = data.docs[index].get('name');
                Timestamp t = data.docs[index].get('time');
                DateTime date = DateTime.fromMicrosecondsSinceEpoch(t.microsecondsSinceEpoch);
                String formattedTime = DateFormat.jm().format(date);
                bool on = data.docs[index].get('onOff');
                if (on) {
                  NotificationLogic.showNotifications(
                    dateTime: date,
                    id: index,
                    title: "PillPal",
                    body: "Don't forget to take your medication",
                  );
                }
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Card(
                          child: ListTile(
                            title: Text(
                              formattedTime,
                              style: const TextStyle(fontSize: 30),
                            ),
                            subtitle: Text(medName),
                            trailing: SizedBox(
                              width: 110,
                              child: Row(
                                children: [
                                  Switcher(
                                    on,
                                    user!.uid,
                                    data.docs[index].id,
                                    data.docs[index].get('time'),
                                    data.docs[index].get('name'),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      deleteReminder(context, data.docs[index].id, user!.uid);
                                    },
                                    icon: const FaIcon(FontAwesomeIcons.circleXmark),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: AppColors.secondaryColor2,
      ),
      child: const Text(
        "PillPal",
        style: TextStyle(
          color: AppColors.blackColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}