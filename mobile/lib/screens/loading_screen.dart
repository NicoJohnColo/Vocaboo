import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/motion/typography_tokens.dart';
import '../providers/auth_provider.dart';

class LoadingScreen extends StatefulWidget {
  final Duration duration;
  final String redirectPath;
  final Map<String, dynamic>? extraParams;

  const LoadingScreen({
    super.key,
    this.duration = const Duration(seconds: 5),
    this.redirectPath = '/home',
    this.extraParams,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  String get _redirectPath => widget.redirectPath;
  late AnimationController _typingController;
  late Animation<int> _typingAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  String _displayText = '';
  
  final List<String> _gifs = [
    'assets/images/gifs/sippy cup says hi.gif',
    'assets/images/gifs/sippy cup happy.gif',
    'assets/images/gifs/sippy cup laughing.gif',
    'assets/images/gifs/grizzy thumbs up.gif',
    'assets/images/gifs/grizzy bear dancing.gif',
    'assets/images/gifs/blue rabbit says hi.gif',
    'assets/images/gifs/bibo star cute.gif',
  ];
  
  final List<Map<String, String>> _tips = [
    {
      'english': 'Cebuano and English have different word orders.',
      'cebuano': 'Lahi ang han-ay sa mga pulong sa Cebuano ug English.',
      'mixed': 'Lahi ang word order sa Cebuano ug English.',
    },
    {
      'english': 'Cebuano verbs can come first.',
      'cebuano': 'Ang verb sa Cebuano mahimong mauna.',
      'mixed': 'Sa Cebuano, ang verb mahimong mauna. Mokaon ko = I will eat.',
    },
    {
      'english': 'Words may move when translated.',
      'cebuano': 'Mahimong mausab ang posisyon sa mga pulong kung hubaron.',
      'mixed': 'Mahimong mausab ang position sa words kung i-translate.',
    },
    {
      'english': 'A noun names a person, place, thing, or idea.',
      'cebuano': 'Ang noun kay ngalan sa tawo, lugar, butang, o ideya.',
      'mixed': 'Ang noun kay ngalan sa person, place, thing, or idea.',
    },
    {
      'english': 'An adjective describes a noun.',
      'cebuano': 'Ang adjective naghulagway sa noun.',
      'mixed': 'Ang adjective kay word nga naghulagway sa noun.',
    },
    {
      'english': 'A verb shows an action.',
      'cebuano': 'Ang verb nagpakita og aksyon.',
      'mixed': 'Ang verb kay word nga nagpakita og action.',
    },
    {
      'english': 'A pronoun replaces a noun.',
      'cebuano': 'Ang pronoun mopuli sa noun.',
      'mixed': 'Ang pronoun kay word nga mopuli sa noun.',
    },
    {
      'english': 'Context can change a word\'s meaning.',
      'cebuano': 'Ang konteksto mahimong makausab sa kahulogan sa pulong.',
      'mixed': 'Ang context mahimong makausab sa meaning sa word.',
    },
    {
      'english': 'Cebuano is often pronounced as spelled.',
      'cebuano': 'Kasagaran, ang Cebuano pulong basahon sumala sa spelling niini.',
      'mixed': 'Kasagaran, ang Cebuano words basahon as they are spelled.',
    },
    {
      'english': 'Learn words in sentences to remember them.',
      'cebuano': 'Pagkat-on og mga pulong pinaagi sa mga sentence aron mas dali kini mahinumdoman.',
      'mixed': 'Pagkat-on og new words through sentences para mas dali nimo mahinumdoman.',
    },
  ];

  late String _selectedGif;
  late List<Map<String, String>> _selectedTips;
  final int _currentTipIndex = 0;
  String _fullText = '';

  @override
  void initState() {
    super.initState();
    
    // Select random GIF for this loading screen (stays static)
    _selectedGif = _gifs[_getRandomIndex(_gifs.length)];
    
    // Select 1 curated tip for this 5-second loading screen
    _selectedTips = _getRandomTips(1);
    
    // Setup progress animation over the 5-second duration
    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_progressController);
    
    // Start typing animation and progress forward after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTipTyping();
      _progressController.forward();
    });
    
    // Schedule completion
    Future.delayed(widget.duration, () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  int _getRandomIndex(int max) {
    return (DateTime.now().millisecondsSinceEpoch % max);
  }

  List<Map<String, String>> _getRandomTips(int count) {
    final List<Map<String, String>> shuffled = List.from(_tips)..shuffle();
    return shuffled.take(count).toList();
  }

  void _startTipTyping() {
    if (_currentTipIndex >= _selectedTips.length) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final languagePreference = auth.learner?.languagePreference ?? 'CEBUANO_TO_ENGLISH';
    
    final currentTip = _selectedTips[_currentTipIndex];
    String fullText;
    switch (languagePreference) {
      case 'FULL_ENGLISH':
        fullText = currentTip['english']!;
        break;
      case 'CEBUANO_ENGLISH_MIXED':
        fullText = currentTip['mixed']!;
        break;
      case 'CEBUANO_TO_ENGLISH':
      default:
        fullText = currentTip['cebuano']!;
        break;
    }
    
    setState(() {
      _fullText = fullText;
      _displayText = '';
    });
    
    // Smooth, brisk typing duration (~1.2s - 1.6s) so tip is fully visible for ~3.5s
    final typingDurationMs = (fullText.length * 30).clamp(800, 1600);
    _typingController = AnimationController(
      duration: Duration(milliseconds: typingDurationMs),
      vsync: this,
    );
    
    _typingAnimation = IntTween(begin: 0, end: fullText.length).animate(_typingController);
    
    _typingController.addListener(() {
      if (mounted) {
        setState(() {
          _displayText = _fullText.substring(0, _typingAnimation.value);
        });
      }
    });
    
    _typingController.forward();
  }

  void _navigateToNextScreen() {
    if (widget.extraParams != null) {
      context.go(_redirectPath, extra: widget.extraParams);
    } else {
      context.go(_redirectPath);
    }
  }

  @override
  void dispose() {
    _typingController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the typing animation text, or full text if animation hasn't started
    final displayText = _displayText.isNotEmpty ? _displayText : _fullText;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/loadingscreen_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // GIF Display - fixed size, no layout changes
                SizedBox(
                  width: 180,
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      _selectedGif,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xFF0EA5E9)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              

              const SizedBox(height: 48),
              
              // Tip text - fixed size container
              SizedBox(
                width: 280,
                height: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      displayText,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Progress indicator - animated tube-like
              Container(
                width: 120,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0), // light grey background for progress bar
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      widthFactor: _progressAnimation.value,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Loading text
              Text(
                'Loading...',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B), // Slate grey
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