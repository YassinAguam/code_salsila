import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/family_member.dart';
import 'home_screen.dart';

class SecurityQuestionsScreen extends StatefulWidget {
  const SecurityQuestionsScreen({Key? key}) : super(key: key);

  @override
  _SecurityQuestionsScreenState createState() => _SecurityQuestionsScreenState();
}

class _SecurityQuestionsScreenState extends State<SecurityQuestionsScreen> {
  // Access the Hive database where family members are stored
  final _familyBox = Hive.box<FamilyMember>('familyTree');

  // List to store security questions and their corresponding answers
  final List<Map<String, String>> _securityQuestionsAndAnswers = [];
  
  // Maximum number of security questions allowed
  final int _maxQuestions = 3;

  // Selected predefined question (nullable)
  String? _selectedQuestion;

  // Controllers for user input
  final _customQuestionController = TextEditingController();
  final _answerController = TextEditingController();

  // List of predefined cultural security questions
  final List<String> predefinedQuestions = [
    "What is your ancestor's birthplace?",
    "What is a famous trait of your ancestor?",
    "Who was the most respected elder in your family?",
    "What is a historical event linked to your ancestor?",
    "What is a known artifact or heirloom of your family?"
  ];

  @override
  void dispose() {
    // Dispose of controllers to free resources when widget is destroyed
    _customQuestionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  /// Adds a security question and answer to the list
  void _addSecurityQuestion() {
    final question = _selectedQuestion ?? _customQuestionController.text.trim();
    final answer = _answerController.text.trim();

    // Validate input: Both question and answer must be provided
    if (question.isEmpty || answer.isEmpty) {
      _showSnackBar("Both question and answer are required.", Colors.red);
      return;
    }

    // Ensure the maximum limit of security questions is not exceeded
    if (_securityQuestionsAndAnswers.length >= _maxQuestions) {
      _showSnackBar("Maximum number of security questions reached.", Colors.red);
      return;
    }

    // Add the question-answer pair to the list
    setState(() {
      _securityQuestionsAndAnswers.add({'question': question, 'answer': answer});
      _customQuestionController.clear();
      _answerController.clear();
      _selectedQuestion = null; // Reset selected question
    });

    _showSnackBar("Security question added (${_securityQuestionsAndAnswers.length}/$_maxQuestions)", Colors.green);
  }

  /// Encrypt and save security questions/answers to the last added ancestor
  void _saveSecurityQuestions() async {
    // Ensure at least 2 questions are added before saving
    if (_securityQuestionsAndAnswers.length < 2) {
      _showSnackBar("Please add at least 2 security questions.", Colors.red);
      return;
    }

    try {
      // Find the last added ancestor from the database
      FamilyMember? lastAncestor;
      int latestKey = -1;
      
      // Find the last added member by finding the highest key
      for (var key in _familyBox.keys) {
        if (key is int && key > latestKey) {
          latestKey = key;
          lastAncestor = _familyBox.get(key);
        }
      }

      if (lastAncestor != null) {
        // Get the encryption key or create a new one if necessary
        String encryptionKey;
        
        // Try to get the existing encryption key
        String? existingKey = lastAncestor.getEncryptionKey();
        
        if (existingKey == null || existingKey.isEmpty) {
          // Generate a new encryption key using the ancestor's data
          encryptionKey = lastAncestor.generateDefaultEncryptionKey();
          
          // Create new encrypted hash with the new key
          String newEncryptedHash = FamilyMember.bitwiseEncrypt(
            encryptionKey, // We're using the key as both the data and the key
            encryptionKey
          );
          
          // Update the ancestor with the new encryption key
          final updatedWithKey = lastAncestor.copyWith(
            encryptedHashedData: newEncryptedHash,
            encryptionKey: encryptionKey,
          );
          
          // Save the ancestor with the new key
          await _familyBox.put(latestKey, updatedWithKey);
          
          // Use the updated ancestor for the rest of the operations
          final encryptedQuestions = _securityQuestionsAndAnswers
              .map((qa) => FamilyMember.bitwiseEncrypt(qa['question']!, encryptionKey))
              .toList();

          final encryptedAnswers = _securityQuestionsAndAnswers
              .map((qa) => FamilyMember.bitwiseEncrypt(qa['answer']!, encryptionKey))
              .toList();

          // Create a new FamilyMember object with encrypted security data
          final updatedAncestor = updatedWithKey.copyWith(
            encryptedSecurityQuestions: encryptedQuestions.cast<String>(),
            encryptedSecurityAnswers: encryptedAnswers.cast<String>(),
          );

          // Save the updated ancestor object back to the database
          await _familyBox.put(latestKey, updatedAncestor);
        } else {
          // Use the existing encryption key
          encryptionKey = existingKey;
          
          final encryptedQuestions = _securityQuestionsAndAnswers
              .map((qa) => FamilyMember.bitwiseEncrypt(qa['question']!, encryptionKey))
              .toList();

          final encryptedAnswers = _securityQuestionsAndAnswers
              .map((qa) => FamilyMember.bitwiseEncrypt(qa['answer']!, encryptionKey))
              .toList();

          // Create a new FamilyMember object with encrypted security data
          final updatedAncestor = lastAncestor.copyWith(
            encryptedSecurityQuestions: encryptedQuestions.cast<String>(),
            encryptedSecurityAnswers: encryptedAnswers.cast<String>(),
          );

          // Save the updated ancestor object back to the database
          await _familyBox.put(latestKey, updatedAncestor);
        }
        
        _showSnackBar("Security questions saved successfully!", Colors.green);

        // Navigate back to the home screen after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false, // Remove all previous routes
          );
        });
      } else {
        _showSnackBar("No ancestor found to save security questions.", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Error saving security questions: $e", Colors.red);
    }
  }

  /// Display a snack bar message
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Security Questions"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add 2-3 Security Questions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              /// Dropdown for predefined security questions
              DropdownButtonFormField<String>(
                value: _selectedQuestion,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Select a security question",
                ),
                items: predefinedQuestions.map((question) {
                  return DropdownMenuItem(
                    value: question,
                    child: Text(question),
                  );
                }).toList()
                  ..add(const DropdownMenuItem(
                    value: "Other",
                    child: Text("Other (Write Your Own)"),
                  )),
                onChanged: (value) {
                  setState(() {
                    _selectedQuestion = value == "Other" ? null : value;
                  });
                },
              ),

              /// Show text field for custom security question if "Other" is selected
              if (_selectedQuestion == null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: _customQuestionController,
                    decoration: const InputDecoration(
                      labelText: "Write your own security question",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

              const SizedBox(height: 10),
              _buildTextField("Security Answer", _answerController),

              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addSecurityQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: Text("Add Security Question (${_securityQuestionsAndAnswers.length}/$_maxQuestions)"),
              ),

              const SizedBox(height: 20),

              /// Display added security questions
              if (_securityQuestionsAndAnswers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Added Security Questions:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      ...List.generate(_securityQuestionsAndAnswers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text("${index + 1}. ${_securityQuestionsAndAnswers[index]['question']}"),
                        );
                      }),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              /// Final save button
              ElevatedButton(
                onPressed: _saveSecurityQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Save & Return", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to create a styled text field
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