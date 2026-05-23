import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/mascot_bubble.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  String? _nameError;
  String? _ageError;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _validateAndProceed() {
    setState(() {
      _nameError = null;
      _ageError = null;
    });

    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();

    bool isValid = true;

    // Validate Name
    if (name.isEmpty) {
      _nameError = 'Please enter your name.';
      isValid = false;
    } else if (!RegExp(r'[a-zA-Z]').hasMatch(name)) {
      _nameError = 'Name must contain at least one letter.';
      isValid = false;
    } else if (RegExp(r'^\d+$').hasMatch(name)) {
      _nameError = 'Name cannot be purely numeric.';
      isValid = false;
    }

    // Validate Age
    if (ageText.isEmpty) {
      _ageError = 'Please enter your age.';
      isValid = false;
    } else {
      final age = int.tryParse(ageText);
      if (age == null || age < 9 || age > 12) {
        _ageError = 'Age must be between 9 and 12.';
        isValid = false;
      }
    }

    if (isValid) {
      // Proceed to PIN setup passing name and age
      context.push(
        '/pin-setup',
        extra: {
          'displayName': name,
          'age': int.parse(ageText),
        },
      );
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Yellow progress bar at 25% (1/4 filled)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(
                    height: 8,
                    child: LinearProgressIndicator(
                      value: 0.25,
                      backgroundColor: Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)), // Amber/Yellow
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Mascot Bubble for Bibo
                const MascotBubble(
                  mascotName: 'bibo',
                  speechText: "Hi! I'm Bibo! What's your name and how old are you?",
                ),
                const SizedBox(height: 36),

                // Name Input
                const Text(
                  'Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Enter name...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFFBBF24), width: 2),
                    ),
                    errorText: _nameError,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 24),

                // Age Input
                const Text(
                  'Age',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ageController,
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Enter age...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFFBBF24), width: 2),
                    ),
                    errorText: _ageError,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 48),

                // NEXT button (black)
                ElevatedButton(
                  onPressed: _validateAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A), // Black
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'NEXT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
