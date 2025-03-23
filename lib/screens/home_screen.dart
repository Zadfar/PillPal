import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mm_project/model/medication_history_model.dart';
import 'package:mm_project/services/notification_logic.dart';
import 'package:mm_project/utils/app_colors.dart';
import 'package:mm_project/widgets/add_reminder.dart';
import 'package:mm_project/widgets/delete_reminder.dart';
import 'package:mm_project/widgets/switcher.dart';
import 'package:mm_project/screens/profile_screen.dart';
import 'package:mm_project/screens/login_screen.dart';
import 'package:mm_project/screens/adherence_screen.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully signed out')));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logout incomplete. Please try again.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to sign out. Please check your connection and try again.')));
    }
  }

  Future<void> _logMedicationTaken(String reminderId, String medName, Timestamp scheduledTime) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final historyEntry = MedicationHistoryModel(
          reminderId: reminderId,
          medicationName: medName,
          timestamp: Timestamp.now(),
          taken: true,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medication_history')
            .add(historyEntry.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication marked as taken!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging medication: $e')),
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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.whiteColor,
          centerTitle: true,
          elevation: 0,
          title: const Text("PillPal", style: TextStyle(color: AppColors.blackColor, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        drawer: Drawer(
          surfaceTintColor: AppColors.lightGrayColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text("Profile Centre", style: TextStyle(color: AppColors.blackColor, fontSize: 16, fontWeight: FontWeight.w500)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
              ),
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text("Medication Tracking", style: TextStyle(color: AppColors.blackColor, fontSize: 16, fontWeight: FontWeight.w500)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdherenceScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings", style: TextStyle(color: AppColors.blackColor, fontSize: 16, fontWeight: FontWeight.w500)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout_outlined),
                title: const Text("Logout", style: TextStyle(color: AppColors.blackColor, fontSize: 16, fontWeight: FontWeight.w500)),
                onTap: _signOut,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          onPressed: () => addReminder(context, user!.uid),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.primaryG, begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(100),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 2))],
            ),
            child: const Center(child: Icon(Icons.add, color: Colors.white, size: 30)),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("users").doc(user!.uid).collection("reminder").snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4FA8C5))));
            }
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
            if (!snapshot.hasData || snapshot.data == null) return const Center(child: Text("No data available"));
            if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Nothing to Show"));

            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.docs.length,
              itemBuilder: (context, index) {
                String medName = data.docs[index].get('name');
                Timestamp t = data.docs[index].get('time');
                DateTime date = DateTime.fromMicrosecondsSinceEpoch(t.microsecondsSinceEpoch);
                String formattedTime = DateFormat.jm().format(date);
                bool on = data.docs[index].get('onOff');
                String frequency = data.docs[index].get('frequency') ?? 'Daily';
                int intervalHours = data.docs[index].get('intervalHours') ?? 1;
                int totalPills = data.docs[index].get('totalPills') ?? 0;
                int pillsPerDose = data.docs[index].get('pillsPerDose') ?? 1;

                int dosesPerDay = frequency == 'Daily' ? (24 ~/ intervalHours) : (24 ~/ (intervalHours * 7));
                int daysUntilRefill = totalPills ~/ (pillsPerDose * dosesPerDay);
                String refillStatus = daysUntilRefill > 3 ? "Refill in $daysUntilRefill days" : "Refill soon!";

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      leading: Text(
                        formattedTime,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.blackColor),
                      ),
                      title: Text(
                        medName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$frequency, Every $intervalHours hr${intervalHours > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grayColor.withOpacity(0.8),
                          ),
                        ),
                      ),
                      trailing: Switcher(on, user!.uid, data.docs[index].id, t, medName),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                refillStatus,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: daysUntilRefill <= 3 ? Colors.red : AppColors.grayColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _logMedicationTaken(data.docs[index].id, medName, t),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Mark Taken'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor1,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => deleteReminder(context, data.docs[index].id, user!.uid),
                                    icon: const FaIcon(FontAwesomeIcons.trash, size: 18),
                                    label: const Text('Delete'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
      decoration: BoxDecoration(color: AppColors.secondaryColor2),
      child: const Text(
        "PillPal",
        style: TextStyle(color: AppColors.blackColor, fontSize: 18, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }
}