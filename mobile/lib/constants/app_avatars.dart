import 'dart:math';
import 'package:flutter/material.dart';

class AppAvatars {
  static const String defaultAvatar = 'prof1.jpg';

  static const List<String> allAvatars = [
    'prof1.jpg',
    'prof2.jpg',
    'prof3.jpg',
    'prof4.jpg',
    'prof5.jpg',
    'prof6.jpg',
    'prof7.jpg',
    'prof8.jpg',
    'prof9.jpg',
  ];

  static const Map<String, String> avatarLabels = {
    'prof1.jpg': 'Banana Monkey',
    'prof2.jpg': 'Curious Frog',
    'prof3.jpg': 'Cheery Guy',
    'prof4.jpg': 'Adventurer Finn',
    'prof5.jpg': 'Cool Smirk',
    'prof6.jpg': 'Chill Capybara',
    'prof7.jpg': 'Thinking Duck',
    'prof8.jpg': 'Thumbs-Up Pup',
    'prof9.jpg': 'Cozy Bear',
  };

  /// Returns clean avatar filename (e.g. 'prof1.jpg'..'prof9.jpg').
  /// If input is null/empty/unrecognized, generates a deterministic avatar from the [seed] (e.g. name or ID)
  /// so learners without an avatar don't all look identical.
  static String normalize(String? avatar, {String? seed}) {
    if (avatar != null && avatar.trim().isNotEmpty) {
      String fileName = avatar.trim().split('/').last;
      if (!fileName.toLowerCase().endsWith('.jpg') &&
          !fileName.toLowerCase().endsWith('.jpeg') &&
          !fileName.toLowerCase().endsWith('.png')) {
        fileName = '$fileName.jpg';
      }
      if (allAvatars.contains(fileName)) {
        return fileName;
      }
    }
    if (seed != null && seed.trim().isNotEmpty) {
      final hash = seed.codeUnits.fold(0, (sum, char) => sum + char);
      return allAvatars[hash.abs() % allAvatars.length];
    }
    return defaultAvatar;
  }

  /// Returns a clean asset path for the given avatar filename.
  static String getAssetPath(String? avatar, {String? seed}) {
    final normalized = normalize(avatar, seed: seed);
    return 'assets/images/profiles/$normalized';
  }

  /// Returns friendly name for avatar.
  static String getLabel(String? avatar, {String? seed}) {
    final normalized = normalize(avatar, seed: seed);
    return avatarLabels[normalized] ?? 'Friend';
  }

  /// Returns a random avatar filename.
  static String getRandomAvatar() {
    final random = Random();
    return allAvatars[random.nextInt(allAvatars.length)];
  }

  /// Generates a deterministic, vibrant background color based on text/initials for fallbacks.
  static Color getColor(String name) {
    const colors = [
      Color(0xFF0EA5E9), // Sky Blue
      Color(0xFF2563EB), // Royal Blue
      Color(0xFFEC4899), // Pink
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFF1D4ED8), // Deep Blue
      Color(0xFF06B6D4), // Cyan
      Color(0xFFF97316), // Orange
    ];
    if (name.isEmpty) return colors[0];
    final hash = name.codeUnits.fold(0, (sum, char) => sum + char);
    return colors[hash % colors.length];
  }

  /// Returns clean uppercase initials.
  static String getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }
}
