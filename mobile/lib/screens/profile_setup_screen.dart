import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/motion/motion.dart';
import '../providers/auth_provider.dart';
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
  bool _isChecking = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _validateAndProceed() async {
    setState(() {
      _nameError = null;
      _ageError = null;
    });

    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    final age = int.tryParse(ageText);

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

    // Validate Age directly
    if (ageText.isEmpty) {
      _ageError = 'Please enter your age.';
      isValid = false;
    } else if (age == null || age < 9 || age > 12) {
      _ageError = 'Age must be between 9 and 12.';
      isValid = false;
    }

    if (!isValid) {
      setState(() {});
      return;
    }

    // Check name availability against backend
    setState(() => _isChecking = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final available = await auth.checkNameAvailable(name);
    setState(() => _isChecking = false);

    if (!available) {
      setState(() {
        _nameError = 'This name is already taken. Please choose another one.';
      });
      return;
    }

    if (mounted) {
      context.push(
        '/grade-selection',
        extra: {'displayName': name, 'age': age!},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        title: const App3DProgressBar(value: 0.20, height: 18.0),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const MascotBubble(
                  mascotName: 'bibo',
                  speechText:
                      "Hi! I'm Bibo! What's your name and how old are you?",
                ),
                const SizedBox(height: 28),

                // Name Input
                Text(
                  'Name',
                  style: AppTypography.baloo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.nunito(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter name...',
                    hintStyle: AppTypography.nunito(
                      color: const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFFBBF24),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 2,
                      ),
                    ),
                    errorText: _nameError,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 24),

                // Age Input
                Text(
                  'Age',
                  style: AppTypography.baloo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ageController,
                  style: AppTypography.nunito(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.cake_outlined,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    hintText: 'Enter age (9-12)...',
                    hintStyle: AppTypography.nunito(
                      color: const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFFBBF24),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 2,
                      ),
                    ),
                    errorText: _ageError,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 48),

                App3DButton(
                  text: 'NEXT',
                  variant: App3DButtonVariant.primary,
                  height: 54,
                  isLoading: _isChecking,
                  onPressed: _validateAndProceed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
