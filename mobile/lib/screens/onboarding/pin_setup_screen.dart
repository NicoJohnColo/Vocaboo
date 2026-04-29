import 'package:flutter/material.dart';
import 'language_preference_screen.dart';

class PinSetupScreen extends StatefulWidget {
  final String name;
  final int age;

  const PinSetupScreen({
    super.key,
    required this.name,
    required this.age,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController pinController = TextEditingController();
  final TextEditingController confirmPinController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    pinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set PIN')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create a PIN to secure your profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: 'Enter PIN (4-6 digits)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 4) {
                      return 'PIN must be at least 4 digits';
                    }
                    if (value.length > 6) {
                      return 'PIN cannot exceed 6 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Confirm your PIN',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: confirmPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: 'Confirm PIN',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != pinController.text) {
                      return 'PINs do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LanguagePreferenceScreen(
                              name: widget.name,
                              age: widget.age,
                              pin: pinController.text,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Next'),
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
