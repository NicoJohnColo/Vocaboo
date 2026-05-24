import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
  DateTime? _selectedBirthday;
  int? _calculatedAge;

  String? _nameError;
  String? _ageError;
  bool _isChecking = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _validateAndProceed() async {
    setState(() {
      _nameError = null;
      _ageError = null;
    });

    final name = _nameController.text.trim();

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

    // Validate Birthday
    if (_selectedBirthday == null) {
      _ageError = 'Please select your birthday.';
      isValid = false;
    } else {
      final today = DateTime.now();
      int age = today.year - _selectedBirthday!.year;
      if (today.month < _selectedBirthday!.month ||
          (today.month == _selectedBirthday!.month && today.day < _selectedBirthday!.day)) {
        age--;
      }
      _calculatedAge = age;
      if (age < 9 || age > 12) {
        _ageError = 'Age must be between 9 and 12.';
        isValid = false;
      }
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
        '/pin-setup',
        extra: {
          'displayName': name,
          'age': _calculatedAge!,
        },
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(
                    height: 8,
                    child: LinearProgressIndicator(
                      value: 0.25,
                      backgroundColor: Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                    ),
                    errorText: _nameError,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 24),

                // Birthday Input
                const Text(
                  'Birthday',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(now.year - 10, now.month, now.day),
                      firstDate: DateTime(now.year - 13),
                      lastDate: DateTime(now.year - 9),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF0F172A),
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Color(0xFF0F172A),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedBirthday = picked;
                        _ageError = null;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _ageError != null
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined, color: Color(0xFF94A3B8), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedBirthday == null
                              ? 'Select birthday...'
                              : '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}',
                          style: TextStyle(
                            color: _selectedBirthday == null
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_ageError != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _ageError!,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 48),

                ElevatedButton(
                  onPressed: _isChecking ? null : _validateAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
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
