import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class InteractionWarning {
  final String drug1;
  final String drug2;
  final String severity;
  final String description;

  InteractionWarning({
    required this.drug1,
    required this.drug2,
    required this.severity,
    required this.description,
  });

  @override
  String toString() {
    return 'Interaction between $drug1 and $drug2: $description (Severity: $severity)';
  }
}

class InteractionService {
  static const String _rxNormBaseUrl = "https://rxnav.nlm.nih.gov/REST";

  Future<List<InteractionWarning>> checkInteractions(
      String newMedicationName, List<String> existingMedicationNames) async {
    if (existingMedicationNames.isEmpty) {
      debugPrint("[InteractionService] No existing medications to check against.");
      return [];
    }

    List<InteractionWarning> warnings = [];
    List<String> allDrugNames = [newMedicationName, ...existingMedicationNames];
    Map<String, String> drugNameToRxCui = {};
    List<String> rxcuis = [];

    debugPrint("[InteractionService] Fetching RxCUIs for: $allDrugNames");
    for (String name in allDrugNames) {
      String? rxcui = await _getRxCuiForDrug(name);
      if (rxcui != null) {
        drugNameToRxCui[name] = rxcui;
        if (!rxcuis.contains(rxcui)) {
          rxcuis.add(rxcui);
        }
      } else {
        debugPrint("[InteractionService] Warning: Could not find RxCUI for '$name'. It will be excluded from interaction check.");
      }
    }

    if (rxcuis.length < 2) {
      debugPrint("[InteractionService] Not enough drugs with RxCUIs found (${rxcuis.length}) to perform interaction check.");
      return [];
    }

    String? newMedRxcui = drugNameToRxCui[newMedicationName];
    if (newMedRxcui == null) {
      debugPrint("[InteractionService] Could not get RxCUI for the newly added medication '$newMedicationName'. Cannot perform interaction check.");
      return [];
    }

    // Mock response for aspirin and warfarin to test the dialog
    if (newMedicationName.toLowerCase() == "aspirin" && existingMedicationNames.contains("warfarin")) {
      warnings.add(InteractionWarning(
        drug1: "aspirin",
        drug2: "warfarin",
        severity: "major",
        description: "Increased risk of bleeding due to combined effects on clotting.",
      ));
      debugPrint("[InteractionService] Mock interaction added for aspirin and warfarin.");
    } else {
      debugPrint("[InteractionService] No mock interaction defined for this pair.");
    }

    /*
    final String rxcuiListString = rxcuis.join('+');
    final interactionApiUrl = '$_rxNormBaseUrl/interaction/list.json?rxcuis=$rxcuiListString';
    debugPrint("[InteractionService] Calling Interaction API: $interactionApiUrl");

    try {
      final response = await http.get(Uri.parse(interactionApiUrl), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['fullInteractionTypeGroup'] != null) {
          for (var group in data['fullInteractionTypeGroup']) {
            if (group['fullInteractionType'] != null) {
              for (var interactionType in group['fullInteractionType']) {
                if (interactionType['interactionPair'] != null) {
                  for (var pair in interactionType['interactionPair']) {
                    List<dynamic>? interactionConcepts = pair['interactionConcept'];
                    List<dynamic>? minConcepts = interactionType['minConcept'];
                    if (interactionConcepts != null && interactionConcepts.isNotEmpty &&
                        minConcepts != null && minConcepts.isNotEmpty) {
                      String? concept1Rxcui = minConcepts[0]['rxcui'];
                      String? concept2Rxcui = interactionConcepts[0]['minConceptItem']['rxcui'];
                      if (concept1Rxcui != null && concept2Rxcui != null &&
                          (concept1Rxcui == newMedRxcui || concept2Rxcui == newMedRxcui)) {
                        String drug1Name = drugNameToRxCui.entries.firstWhere((entry) => entry.value == concept1Rxcui, orElse: () => MapEntry('Unknown ($concept1Rxcui)', '')).key;
                        String drug2Name = drugNameToRxCui.entries.firstWhere((entry) => entry.value == concept2Rxcui, orElse: () => MapEntry('Unknown ($concept2Rxcui)', '')).key;
                        bool alreadyAdded = warnings.any((w) =>
                          (w.drug1 == drug1Name && w.drug2 == drug2Name) ||
                          (w.drug1 == drug2Name && w.drug2 == drug1Name));
                        if (!alreadyAdded && drug1Name != drug2Name) {
                          warnings.add(InteractionWarning(
                            drug1: (concept1Rxcui == newMedRxcui) ? drug1Name : drug2Name,
                            drug2: (concept1Rxcui == newMedRxcui) ? drug2Name : drug1Name,
                            severity: pair['severity']?.toLowerCase() ?? 'unknown',
                            description: pair['description'] ?? 'No description available.',
                          ));
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        } else {
          if (data['comment'] != null) {
            debugPrint("[InteractionService] API Comment: ${data['comment']}");
          } else {
            debugPrint("[InteractionService] No 'fullInteractionTypeGroup' found in response and no comment.");
          }
        }
      } else {
        debugPrint('[InteractionService] Interaction API request failed with status: ${response.statusCode}');
        debugPrint('[InteractionService] Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint("[InteractionService] Error calling or parsing Interaction API: $e");
      debugPrint("[InteractionService] StackTrace: $stackTrace");
    }
    */

    debugPrint('[InteractionService] Found ${warnings.length} potential interactions involving $newMedicationName.');
    return warnings;
  }

  Future<String?> _getRxCuiForDrug(String drugName) async {
    final url = '$_rxNormBaseUrl/rxcui.json?name=${Uri.encodeComponent(drugName)}&search=2';
    debugPrint("[InteractionService] Getting RxCUI for '$drugName': $url");

    try {
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['idGroup'] != null && data['idGroup']['rxnormId'] != null && data['idGroup']['rxnormId'].isNotEmpty) {
          final rxcui = data['idGroup']['rxnormId'][0];
          debugPrint("[InteractionService] Found RxCUI $rxcui for '$drugName'");
          return rxcui;
        } else {
          debugPrint("[InteractionService] No RxCUI found in response for '$drugName'");
          return null;
        }
      } else {
        debugPrint("[InteractionService] RxCUI lookup failed for '$drugName' - Status: ${response.statusCode}, Body: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("[InteractionService] Error fetching RxCUI for $drugName: $e");
      return null;
    }
  }
}