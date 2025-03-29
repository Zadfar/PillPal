import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mm_project/model/medication_history_model.dart';
import 'package:mm_project/screens/profile_screen.dart';
import 'package:mm_project/services/notification_logic.dart';
import 'package:mm_project/utils/app_colors.dart';
import 'package:mm_project/widgets/add_reminder.dart';
import 'package:mm_project/widgets/delete_reminder.dart';
import 'package:mm_project/widgets/switcher.dart';
import 'package:mm_project/screens/profile_center_screen.dart';
import 'package:mm_project/screens/login_screen.dart';
import 'package:mm_project/screens/adherence_screen.dart';

class HomeScreen extends StatefulWidget {
  final String profileId;
  const HomeScreen({super.key, required this.profileId});

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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to sign out.')));
    }
  }

  Future<void> _logMedicationTaken(String reminderId, String medName, Timestamp scheduledTime) async {
    try {
      if (user != null) {
        final historyEntry = MedicationHistoryModel(
          reminderId: reminderId,
          medicationName: medName,
          timestamp: Timestamp.now(),
          taken: true,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('profiles')
            .doc(widget.profileId)
            .collection('medication_history')
            .add(historyEntry.toMap());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medication marked as taken!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error logging medication: $e')));
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
      NotificationLogic.init(
        onNotificationTap: (payload) {
          if (payload != null && mounted) {
            final parts = payload.split('|');
            final profileId = parts[0];
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(profileId: profileId)),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('profiles').doc(widget.profileId);
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
              _buildHeader(context, widget.profileId , userRef),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text("Profile Center", style: TextStyle(color: AppColors.blackColor, fontSize: 16, fontWeight: FontWeight.w500)),
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileCenterScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text("Medication Tracking", style: TextStyle(color: AppColors.blackColor, fontSize: 16, fontWeight: FontWeight.w500)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdherenceScreen(profileId: widget.profileId))),
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
          onPressed: () => addReminder(context, user!.uid, widget.profileId),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.primaryG, begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Center(child: Icon(Icons.add, color: Colors.white, size: 30)),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(user!.uid)
              .collection("profiles")
              .doc(widget.profileId)
              .collection("reminder")
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No reminders yet"));

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
                      leading: Text(formattedTime, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.blackColor)),
                      title: Text(medName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('$frequency, Every $intervalHours hr${intervalHours > 1 ? 's' : ''}', style: TextStyle(fontSize: 14, color: AppColors.grayColor.withOpacity(0.8))),
                      ),
                      trailing: Switcher(on, user!.uid, data.docs[index].id, t, medName, widget.profileId),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(refillStatus, style: TextStyle(fontSize: 14, color: daysUntilRefill <= 3 ? Colors.red : AppColors.grayColor)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _logMedicationTaken(data.docs[index].id, medName, t),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Mark Taken'),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor1, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => deleteReminder(context, data.docs[index].id, user!.uid, widget.profileId),
                                    icon: const FaIcon(FontAwesomeIcons.trash, size: 18),
                                    label: const Text('Delete'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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

  Widget _buildHeader(BuildContext context, String profileId, DocumentReference userRef) {

    return StreamBuilder(stream: userRef.snapshots(), builder: 
    (context, snapshot) {
      final userData = snapshot.data;
      return SizedBox(
      height: 250,
      child: DrawerHeader(
        decoration: BoxDecoration(color: AppColors.secondaryColor2),
        child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(profileId: profileId),
            ),
          );
        },
        child: Column(
          children: [
            SizedBox(height: 15,),
            const CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.whiteColor,
                              child: Icon(Icons.person, size: 60, color: AppColors.grayColor),
            ),
            SizedBox(height: 15,),
            Text(
              userData?['fullName'] ?? '',
              style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.blackColor,
              ),
            ),
          ],
        ),
        ),
      ),
    );
    });
  }
}