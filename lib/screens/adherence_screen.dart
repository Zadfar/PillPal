import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:mm_project/model/medication_history_model.dart';
import 'package:mm_project/utils/app_colors.dart';

class AdherenceScreen extends StatefulWidget {
  const AdherenceScreen({super.key});

  @override
  State<AdherenceScreen> createState() => _AdherenceScreenState();
}

class _AdherenceScreenState extends State<AdherenceScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Calculate adherence percentage for the last 7 days
  Future<Map<String, double>> _getAdherenceData() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medication_history')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .get();

    Map<String, int> takenCount = {};
    Map<String, int> totalCount = {};

    for (var doc in snapshot.docs) {
      final history = MedicationHistoryModel.fromMap(doc.data());
      final dateStr = DateFormat('yyyy-MM-dd').format(history.timestamp.toDate());
      takenCount[dateStr] = (takenCount[dateStr] ?? 0) + (history.taken ? 1 : 0);
      totalCount[dateStr] = (totalCount[dateStr] ?? 0) + 1;
    }

    Map<String, double> adherence = {};
    totalCount.forEach((date, total) {
      final taken = takenCount[date] ?? 0;
      adherence[date] = total > 0 ? (taken / total) * 100 : 0;
    });

    return adherence;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adherence Tracking'),
        backgroundColor: AppColors.secondaryColor2,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, double>>(
          future: _getAdherenceData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No adherence data available yet.'));
            }

            final adherenceData = snapshot.data!;
            final sortedDates = adherenceData.keys.toList()..sort();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Adherence Over Last 7 Days',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: sortedDates.map((date) {
                        final index = sortedDates.indexOf(date);
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: adherenceData[date]!,
                              color: AppColors.primaryColor1,
                              width: 20,
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= sortedDates.length) return const Text('');
                              final date = DateTime.parse(sortedDates[index]);
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(DateFormat('MM/dd').format(date)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text('${value.toInt()}%'),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: true),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Overall Adherence: ${(adherenceData.values.reduce((a, b) => a + b) / adherenceData.length).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}