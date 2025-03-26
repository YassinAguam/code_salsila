import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/family_member.dart';

/// This screen handles the verification of security questions.
/// The user must correctly answer a certain percentage of questions
/// to confirm their kinship with a matched ancestor.
class VerifySecurityQuestionsScreen extends StatefulWidget {
  /// The family member (ancestor) that the user is attempting to verify.
  final FamilyMember matchedPerson;

  /// Constructor requires the matched ancestor to be passed.
  const VerifySecurityQuestionsScreen({Key? key, required this.matchedPerson})
      : super(key: key);

  @override
  _VerifySecurityQuestionsScreenState createState() =>
      _VerifySecurityQuestionsScreenState();
}

class _VerifySecurityQuestionsScreenState
    extends State<VerifySecurityQuestionsScreen> {
  /// Stores user input for each security question.
  final Map<String, TextEditingController> _answerControllers = {};

  /// Counts how many answers were correct.
  int _correctAnswers = 0;

  /// Stores the percentage of correct answers.
  double _matchPercentage = 0.0;

  /// Disposes of text controllers to free up memory when the widget is removed.
  @override
  void dispose() {
    for (var controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Verifies the user's answers against the decrypted correct answers.
  void _verifyAnswers() {
    _correctAnswers = 0;

    // Get decrypted answers and questions from the matched ancestor
    List<String>? correctAnswers = widget.matchedPerson.getDecryptedSecurityAnswers();
    List<String>? securityQuestions = widget.matchedPerson.getDecryptedSecurityQuestions();

    // If security questions or answers are missing, verification fails immediately.
    if (correctAnswers == null || correctAnswers.isEmpty || securityQuestions == null) {
      _showFailedVerification();
      return;
    }

    // Loop through each question and compare user input with the correct answer.
    for (int i = 0; i < correctAnswers.length; i++) {
      final controller = _answerControllers[securityQuestions[i]];
      if (controller == null) continue; // Skip if the controller is missing.

      String userAnswer = controller.text.trim().toLowerCase(); // Normalize input.
      String expectedAnswer = correctAnswers[i].toLowerCase(); // Normalize correct answer.

      if (userAnswer == expectedAnswer) {
        _correctAnswers++; // Increment count if answer matches.
      }
    }

    // Calculate the percentage of correct answers.
    _matchPercentage = (_correctAnswers / correctAnswers.length) * 100;

    // Define a pass threshold of 75%.
    if (_matchPercentage >= 75.0) {
      _showKinshipResult();
    } else {
      _showFailedVerification();
    }
  }

  /// Displays a dialog when kinship verification is successful.
  void _showKinshipResult() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Kinship Verified!", style: TextStyle(color: Colors.green)),
        content: Text(
          "You are related to ${widget.matchedPerson.firstName} ${widget.matchedPerson.lastName}.\n"
          "Common Ancestor: ${widget.matchedPerson.relationshipType}.\n"
          "Match Score: ${_matchPercentage.toStringAsFixed(1)}%", // Show match score.
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close the dialog.
            child: const Text("OK", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  /// Displays a dialog when verification fails due to insufficient correct answers.
  void _showFailedVerification() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Verification Failed", style: TextStyle(color: Colors.red)),
        content: const Text("You did not meet the required match percentage."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close the dialog.
            child: const Text("OK", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve decrypted security questions.
    List<String>? securityQuestions = widget.matchedPerson.getDecryptedSecurityQuestions();

    // If there are no questions stored for the ancestor, display an error message.
    if (securityQuestions == null || securityQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Answer Security Questions"),
          backgroundColor: Colors.blue,
        ),
        backgroundColor: Colors.white,
        body: const Center(
          child: Text("No security questions available."), // Inform the user.
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Answer Security Questions"),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Answer the following security questions:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Display all security questions in a scrollable list.
            Expanded(
              child: ListView.builder(
                itemCount: securityQuestions.length,
                itemBuilder: (context, index) {
                  final question = securityQuestions[index];

                  // Ensure a TextEditingController exists for each question.
                  _answerControllers.putIfAbsent(question, () => TextEditingController());

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(question), // Display the security question.
                      TextField(
                        controller: _answerControllers[question], // User input field.
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Enter your answer",
                        ),
                      ),
                      const SizedBox(height: 10), // Spacing between fields.
                    ],
                  );
                },
              ),
            ),

            // Button to verify answers.
            ElevatedButton(
              onPressed: _verifyAnswers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text("Verify Answers"),
            ),
          ],
        ),
      ),
    );
  }
}
