import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CumulativeReviewSummaryScreen extends StatelessWidget {
  final String sessionId;
  final int correct;
  final int total;

  const CumulativeReviewSummaryScreen({
    super.key,
    required this.sessionId,
    required this.correct,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final double accuracy = total > 0 ? (correct / total) * 100 : 0.0;
    
    String badge = 'Try Again';
    Color badgeColor = Colors.grey;
    if (accuracy >= 90) { badge = 'GOLD'; badgeColor = const Color(0xFFF59E0B); }
    else if (accuracy >= 80) { badge = 'SILVER'; badgeColor = const Color(0xFF94A3B8); }
    else if (accuracy >= 70) { badge = 'BRONZE'; badgeColor = const Color(0xFFB45309); }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Complete'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Score: ${accuracy.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Badge: $badge', style: TextStyle(fontSize: 24, color: badgeColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Return Home'),
            ),
          ],
        ),
      ),
    );
  }
}
