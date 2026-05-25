import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/mascot_bubble.dart';

class PinSetupScreen extends StatefulWidget {
  final Map<String, dynamic> learnerData;

  const PinSetupScreen({super.key, required this.learnerData});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _pinFocus = FocusNode();
  final _confirmPinFocus = FocusNode();
  String? _errorText;
  bool _isPinVisible = false;

  @override
  void initState() {
    super.initState();
    // Rebuild screen when pin changes to update the visual circles
    _pinController.addListener(() => setState(() {}));
    _confirmPinController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _pinFocus.dispose();
    _confirmPinFocus.dispose();
    super.dispose();
  }

  void _validateAndProceed() {
    setState(() {
      _errorText = null;
    });

    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.length != 4 || confirmPin.length != 4) {
      setState(() {
        _errorText = 'Both PINs must be exactly 4 digits.';
      });
      return;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(pin) || !RegExp(r'^\d{4}$').hasMatch(confirmPin)) {
      setState(() {
        _errorText = 'PIN must contain only numbers.';
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorText = 'PINs do not match. Please try again.';
        _pinController.clear();
        _confirmPinController.clear();
      });
      return;
    }

    // PIN is correct, advance to LanguagePreferenceScreen
    context.push(
      '/language-preference',
      extra: {
        'displayName': widget.learnerData['displayName'],
        'age': widget.learnerData['age'],
        'pin': pin,
      },
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => focusNode.requestFocus(),
      child: SizedBox(
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Transparent but fully interactive TextField — captures keystrokes
            // and shows the keyboard without rendering any visible text or cursor.
            Opacity(
              opacity: 0.0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: false,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontSize: 1),
                cursorColor: Colors.transparent,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            // Four circles drawn on top — IgnorePointer so taps fall through
            // to the TextField above for proper focus + keyboard handling.
            IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  final isFilled = controller.text.length > index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? const Color(0xFF0F172A)
                          : Colors.transparent,
                      border: Border.all(
                        color: isFilled
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF94A3B8),
                        width: 2,
                      ),
                    ),
                    child: isFilled
                        ? Center(
                            child: _isPinVisible
                                ? Text(
                                    controller.text[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const CircleAvatar(
                                    radius: 7,
                                    backgroundColor: Colors.white,
                                  ),
                          )
                        : null,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Yellow progress bar at 50% (2/4 filled)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: 0.50,
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Mascot Bubble for Toti
              const MascotBubble(
                mascotName: 'toti',
                speechText: "Hi! I'm Toti! Can you make a 4-digit secret PIN?",
              ),
              const SizedBox(height: 28),

              if (_errorText != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ENTER PIN Circle visual representation
              const Text(
                'Enter PIN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 12),
              _buildPinField(controller: _pinController, focusNode: _pinFocus),
              const SizedBox(height: 36),

              // CONFIRM PIN Circle visual representation
              const Text(
                'Confirm PIN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 12),
              _buildPinField(controller: _confirmPinController, focusNode: _confirmPinFocus),
              const SizedBox(height: 12),

              // Show/Hide PIN visibility toggle Row
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isPinVisible = !_isPinVisible;
                    });
                  },
                  icon: Icon(
                    _isPinVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  label: Text(
                    _isPinVisible ? 'Hide PIN' : 'Show PIN',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

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
    );
  }
}
