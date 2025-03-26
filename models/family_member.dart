import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

part 'family_member.g.dart';

@HiveType(typeId: 0)
class FamilyMember extends HiveObject {
  // Unique identifier for the family member
  @HiveField(0)
  final String id;

  // Personal details
  @HiveField(1)
  final String firstName;
  @HiveField(2)
  final String middleName;
  @HiveField(3)
  final String lastName;
  @HiveField(4)
  final String birthDate;

  // Encrypted security questions and answers
  @HiveField(5)
  final List<String> encryptedSecurityQuestions;
  @HiveField(6)
  final List<String> encryptedSecurityAnswers;

  // Encrypted hash for identity verification
  @HiveField(7)
  final String encryptedHashedData;

  // Encryption key (optional, private field)
  @HiveField(8)
  final String? _encryptionKey;

  // Parent ID to establish genealogy relationships
  @HiveField(9)
  final String? parentId;

  // Relationship type (e.g., father, mother, sibling)
  @HiveField(10)
  final String relationshipType;

  // Generation level in the family tree
  @HiveField(11)
  int generationLevel;

  FamilyMember({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.birthDate,
    required this.encryptedSecurityQuestions,
    required this.encryptedSecurityAnswers,
    required this.encryptedHashedData,
    required this.relationshipType,
    required this.generationLevel,
    String? encryptionKey,
    this.parentId,
  }) : _encryptionKey = encryptionKey;

  // Factory constructor to create a new FamilyMember with encrypted data
  factory FamilyMember.create({
    required String id,
    required String firstName,
    required String middleName,
    required String lastName,
    required String birthDate,
    required List<String> securityQuestions,
    required List<String> securityAnswers,
    required int generationLevel,
    String? parentId,
    required String relationshipType,
  }) {
    final encryptionKey = const Uuid().v4(); // Generate a random encryption key

    return FamilyMember(
      id: id,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      birthDate: birthDate,
      encryptedSecurityQuestions: securityQuestions
          .map((question) => _bitwiseEncrypt(question, encryptionKey))
          .toList(),
      encryptedSecurityAnswers: securityAnswers
          .map((answer) => _bitwiseEncrypt(answer, encryptionKey))
          .toList(),
      encryptedHashedData: _bitwiseEncrypt(
        _generateHash(firstName, middleName, lastName, birthDate, encryptionKey),
        encryptionKey,
      ),
      encryptionKey: encryptionKey,
      parentId: parentId,
      relationshipType: relationshipType,
      generationLevel: generationLevel,
    );
  }

  // Method to create a modified copy of a FamilyMember
  FamilyMember copyWith({
    List<String>? encryptedSecurityQuestions,
    List<String>? encryptedSecurityAnswers,
    String? newParentId,
    int? newGenerationLevel,
    String? encryptedHashedData,
    String? encryptionKey,
  }) {
    return FamilyMember(
      id: id,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      birthDate: birthDate,
      encryptedSecurityQuestions: encryptedSecurityQuestions ?? this.encryptedSecurityQuestions,
      encryptedSecurityAnswers: encryptedSecurityAnswers ?? this.encryptedSecurityAnswers,
      encryptedHashedData: encryptedHashedData ?? this.encryptedHashedData,
      relationshipType: relationshipType,
      generationLevel: newGenerationLevel ?? generationLevel,
      encryptionKey: encryptionKey ?? _encryptionKey,
      parentId: newParentId ?? parentId,
    );
  }

  // Generates a SHA-256 hash for identity verification
  static String _generateHash(String firstName, String middleName, String lastName, String birthDate, String salt) {
    String rawData = "$firstName $middleName $lastName|$birthDate|$salt";
    return sha256.convert(utf8.encode(rawData)).toString();
  }

  // Bitwise XOR encryption for storing sensitive information
  static String _bitwiseEncrypt(String value, String key) {
    List<int> encryptedCodes = value.codeUnits
        .asMap()
        .entries
        .map((entry) => entry.value ^ key.codeUnitAt(entry.key % key.length))
        .toList();
    return base64.encode(encryptedCodes);
  }

  // Bitwise XOR decryption to retrieve original data
  static String _bitwiseDecrypt(String encryptedValue, String key) {
    try {
      List<int> encryptedCodes = base64.decode(encryptedValue);
      List<int> decryptedCodes = encryptedCodes
          .asMap()
          .entries
          .map((entry) => entry.value ^ key.codeUnitAt(entry.key % key.length))
          .toList();
      return String.fromCharCodes(decryptedCodes);
    } catch (e) {
      debugPrint("Decryption failed: $e");
      return "";
    }
  }

  // Make this method public to allow access from outside the class
  static String bitwiseEncrypt(String value, String key) {
    return _bitwiseEncrypt(value, key);
  }

  // Make this method public to allow access from outside the class
  static String bitwiseDecrypt(String encryptedValue, String key) {
    return _bitwiseDecrypt(encryptedValue, key);
  }

  // Validates security answer by decrypting and comparing
  bool validateSecurityAnswer(String inputAnswer, String encryptedAnswer) {
    if (_encryptionKey == null) return false;
    final decrypted = _bitwiseDecrypt(encryptedAnswer, _encryptionKey!);
    return decrypted.toLowerCase() == inputAnswer.toLowerCase();
  }

  // Retrieves decrypted hash if encryption key is available
  String? getDecryptedHash() {
    if (_encryptionKey == null || _encryptionKey!.isEmpty) return null;
    try {
      return _bitwiseDecrypt(encryptedHashedData, _encryptionKey!);
    } catch (e) {
      debugPrint("Failed to decrypt hash: $e");
      return null;
    }
  }

  // Get the raw encryption key (only for internal use)
  String? getEncryptionKey() {
    return _encryptionKey;
  }

  // Retrieves decrypted security questions
  List<String>? getDecryptedSecurityQuestions() {
    if (_encryptionKey == null) return null;
    return encryptedSecurityQuestions.map((q) => _bitwiseDecrypt(q, _encryptionKey!)).toList();
  }

  // Retrieves decrypted security answers
  List<String>? getDecryptedSecurityAnswers() {
    if (_encryptionKey == null) return null;
    return encryptedSecurityAnswers.map((a) => _bitwiseDecrypt(a, _encryptionKey!)).toList();
  }

  // Generate a default encryption key based on FamilyMember data
  String generateDefaultEncryptionKey() {
    String baseKey = "$firstName$lastName$id";
    
    // Ensure the key is at least 16 characters
    while (baseKey.length < 16) {
      baseKey += baseKey;
    }
    
    // Return first 16 characters as the key
    return baseKey.substring(0, 16);
  }

  // Fixed to return a valid FamilyMember for orElse instead of null
  List<FamilyMember> traceAncestors(Box<FamilyMember> box) {
    List<FamilyMember> path = [];
    FamilyMember? current = this;
    while (current != null && current.parentId != null) {
      FamilyMember? parent;
      try {
        parent = box.values.firstWhere(
          (m) => m.id == current!.parentId,
        );
        path.add(parent);
        current = parent;
      } catch (e) {
        // No parent found
        break;
      }
    }
    return path;
  }
}