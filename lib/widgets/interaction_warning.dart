import 'package:flutter/material.dart';
import 'package:mm_project/services/interaction_service.dart';
import 'package:mm_project/utils/app_colors.dart';

Future<void> showInteractionDialog(BuildContext context, List<InteractionWarning> warnings) {
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red.shade700;
      case 'moderate':
        return Colors.orange.shade800;
      case 'low':
        return Colors.blueGrey.shade600;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatSeverity(String severity) {
    if (severity.toLowerCase() == 'n/a') return 'N/A';
    return severity[0].toUpperCase() + severity.substring(1);
  }

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Potential Interactions Found',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              const Text(
                'PillPal found potential interactions involving the medication you just added. Please review carefully:',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 15),

              ...warnings.map((warning) {
                Color severityColor = _getSeverityColor(warning.severity);
                String formattedSeverity = _formatSeverity(warning.severity);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.shade300, width: 1)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15), // Base style
                            children: <TextSpan>[
                              TextSpan(text: '• ${warning.drug1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const TextSpan(text: '  &  '),
                              TextSpan(text: warning.drug2, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                         Align(
                            alignment: Alignment.centerLeft,
                            child: Chip(
                              label: Text(formattedSeverity, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              backgroundColor: severityColor,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              labelPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                             ),
                           ),
                        // Description
                        Padding(
                           padding: const EdgeInsets.only(top: 8.0),
                           child: Text(
                            warning.description,
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                           ),
                         ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),
              // Disclaimer Section
              const Text(
                'Disclaimer:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 5),
              const Text(
                'This information is automatically generated and may not be exhaustive or entirely accurate. It is NOT a substitute for professional medical advice. Always consult your doctor or pharmacist before making any decisions about your medication regimen.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: AppColors.grayColor), // Use your app's gray color
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12)
            ),
            child: const Text(
              'Acknowledge',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
}