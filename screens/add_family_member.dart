import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/family_member.dart';
import 'security_questions_screen.dart'; // Screen for security questions setup
import 'package:uuid/uuid.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  const AddFamilyMemberScreen({Key? key}) : super(key: key);

  @override
  _AddFamilyMemberScreenState createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  // Text controllers for input fields
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _familyBox = Hive.box<FamilyMember>('familyTree');

  bool _ancestorAdded = false; // Flag to show the "Proceed" button after adding

  /// Validates required inputs and ensures birthdate is in correct format
  bool _validateInputs() {
    if (_firstNameController.text.trim().isEmpty ||
        _middleNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _relationshipController.text.trim().isEmpty) {
      _showSnackBar("Please enter ancestor's full name and relationship.", Colors.red);
      return false;
    }

    if (_birthDateController.text.trim().isNotEmpty &&
        !_isValidDate(_birthDateController.text.trim())) {
      _showSnackBar("Invalid birthdate. Use YYYY-MM-DD format.", Colors.red);
      return false;
    }
    return true;
  }

  /// Checks if the entered birthdate follows the YYYY-MM-DD format
  bool _isValidDate(String input) {
    try {
      DateTime.parse(input);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Displays a message at the bottom of the screen
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  /// Saves ancestor information into local Hive storage
  void _saveAncestor() async {
    if (!_validateInputs()) return;

    final uuid = Uuid();

    try {
      // Attempt to find a parent by relationship type
      FamilyMember? parent;
      
      if (_familyBox.values.isNotEmpty) {
        // Using try-catch to handle the case when no matching member is found
        try {
          parent = _familyBox.values.firstWhere(
            (member) => member.relationshipType.toLowerCase() ==
                _relationshipController.text.trim().toLowerCase(),
          );
        } catch (e) {
          // No parent found, that's okay
          parent = null;
        }
      }

      // Determine generation level based on parent's level
      int newGenerationLevel = parent != null ? parent.generationLevel + 1 : 1;

      // Ensure the family tree does not exceed 5 generations
      if (newGenerationLevel > 5) {
        _showSnackBar("Cannot add ancestors beyond generation level 5.", Colors.red);
        return;
      }

      // Create a new family member with empty security questions
      final newFamilyMember = FamilyMember.create(
        id: uuid.v4(),
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        securityQuestions: [],
        securityAnswers: [],
        generationLevel: newGenerationLevel,
        parentId: parent?.id,
        relationshipType: _relationshipController.text.trim(),
      );

      // Save to Hive database
      await _familyBox.add(newFamilyMember);

      setState(() {
        _ancestorAdded = true; // Show "Proceed" button
      });

      _showSnackBar("Ancestor added successfully!", Colors.green);
    } catch (e) {
      _showSnackBar("Failed to add ancestor: $e", Colors.red);
    }
  }

  /// Builds the screen layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Ancestor"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField("First Name *", _firstNameController),
              _buildTextField("Middle Name *", _middleNameController),
              _buildTextField("Last Name *", _lastNameController),
              _buildTextField("Birthdate (YYYY-MM-DD) [Optional]", _birthDateController),
              _buildTextField("Relationship*", _relationshipController),
              const SizedBox(height: 20),

              // Show Save button if ancestor has not been added
              if (!_ancestorAdded)
                ElevatedButton(
                  onPressed: _saveAncestor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: const Text("Save Ancestor"),
                ),

              const SizedBox(height: 20),

              // Once added, show navigation to security questions screen
              if (_ancestorAdded)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SecurityQuestionsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: const Text("Proceed to Security Questions"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Generates a styled text field
  Widget _buildTextField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}