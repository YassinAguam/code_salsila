import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import '../models/family_member.dart';
import 'verify_security_questions_screen.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({Key? key}) : super(key: key);

  @override
  _ScanQRScreenState createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final _familyBox = Hive.box<FamilyMember>('familyTree');
  bool _scanning = true;

  /// Extract ancestor hashes for all local family members
  List<String> _getLocalAncestorHashes() {
    List<String> allHashes = [];
    for (var member in _familyBox.values) {
      // Traverse up to the root
      List<FamilyMember> ancestors = member.traceAncestors(_familyBox);
      for (var ancestor in ancestors) {
        String? hash = ancestor.getDecryptedHash();
        if (hash != null) allHashes.add(hash);
      }
    }
    return allHashes.toSet().toList(); // Remove duplicates
  }

  /// Process scanned QR and look for a common ancestor
  void _processScan(String scannedData) {
    if (!_scanning) return;

    setState(() {
      _scanning = false;
    });

    try {
      Map<String, dynamic> familyData = jsonDecode(scannedData);
      List<String> scannedHashes = [];

      // Extract all encrypted hash strings from QR data
      familyData.forEach((key, value) {
        if (key.startsWith("member_") && value.containsKey("hashedData")) {
          scannedHashes.add(value["hashedData"]);
        }
      });

      // Convert local encrypted hashes to decrypted ones for comparison
      List<String> localDecryptedHashes = _getLocalAncestorHashes();

      // Compare: find first match between local and scanned ancestor hashes
      FamilyMember? matchedPerson;
      for (var person in _familyBox.values) {
        String? localHash = person.getDecryptedHash();
        if (localHash != null && scannedHashes.contains(localHash)) {
          matchedPerson = person;
          break;
        }
      }

      if (matchedPerson != null) {
        // Match found — proceed to answer security questions
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifySecurityQuestionsScreen(matchedPerson: matchedPerson!),
          ),
        );
      } else {
        // No match — alert user
        _showNoRelationMessage();
        setState(() {
          _scanning = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Invalid QR code or data format. Error: $e"),
        backgroundColor: Colors.red,
      ));
      setState(() {
        _scanning = true;
      });
    }
  }

  /// Displays an alert dialog when no relation is found
  void _showNoRelationMessage() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("No Kinship Match Found", style: TextStyle(color: Colors.red)),
        content: const Text(
          "The scanned QR code does not match any known family records.",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _scanning = true;
              });
            },
            child: const Text("OK", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Scanner view
          Expanded(
            flex: 4,
            child: MobileScanner(
              onDetect: (BarcodeCapture capture) {
                if (!_scanning) return;
                for (final barcode in capture.barcodes) {
                  final String? code = barcode.rawValue;
                  if (code != null) {
                    _processScan(code);
                    break;
                  }
                }
              },
            ),
          ),
          // Instructions
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("Align QR Code within the frame", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text("Scanning...", style: TextStyle(fontSize: 14, color: Colors.green)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
