import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/family_member.dart';

class GenerateQRScreen extends StatelessWidget {
  const GenerateQRScreen({Key? key}) : super(key: key);

  // Shared secret key used to generate HMAC signature for verifying authenticity
  final String secretKey = "your_secret_key";

  @override
  Widget build(BuildContext context) {
    final _familyBox = Hive.box<FamilyMember>('familyTree');

    /// Generates QR data string with encrypted family tree data
    String generateQRData() {
      try {
        Map<String, dynamic> familyData = {};

        // Loop through each ancestor stored in Hive database
        for (var member in _familyBox.values) {
          // Create a structured data entry for each family member
          String memberKey = "member_${member.id}";
          familyData[memberKey] = {
            "hashedData": member.encryptedHashedData, // Securely stored data
            "securityQuestions": member.encryptedSecurityQuestions,
            "securityAnswers": member.encryptedSecurityAnswers,
            "generationLevel": member.generationLevel,
            "timestamp": DateTime.now().toIso8601String(), // Timestamp for validation
          };
        }

        // Generate an HMAC signature to ensure data integrity on scanning
        familyData["signature"] = _generateHmacSignature(familyData, secretKey);

        return jsonEncode(familyData); // Convert map to JSON string for QR encoding
      } catch (e) {
        debugPrint("Error generating QR data: $e");
        return jsonEncode({"error": "Failed to generate QR data"});
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate QR Code"),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Instructional text
            const Text(
              "Scan this QR to verify kinship",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "This QR code contains encrypted ancestor",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // QR Code Display Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: QrImageView(
                data: generateQRData(), // Dynamically generated QR code with encrypted data
                version: QrVersions.auto,
                size: 300.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generates a secure HMAC signature using SHA-256 hashing and a shared key
  /// This ensures that the QR code's data remains tamper-proof and verifiable
  String _generateHmacSignature(Map<String, dynamic> data, String key) {
    final jsonData = jsonEncode(data); // Convert data to JSON string
    final hmac = Hmac(sha256, utf8.encode(key)); // Create HMAC using SHA-256
    return base64.encode(hmac.convert(utf8.encode(jsonData)).bytes); // Return base64 encoded signature
  }
}
