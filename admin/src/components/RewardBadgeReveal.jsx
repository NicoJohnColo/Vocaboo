import React, { useState, useEffect } from 'react';

/**
 * Duolingo-style Lesson-Completion Reward Badge Reveal Component.
 *
 * Props:
 * - tier: 'gold' | 'silver' | 'bronze'
 * - title: string
 * - subtitle: string
 * - size: number (default: 110)
 * - autoPlay: boolean
 * - onComplete: callback
 */
export default function RewardBadgeReveal({
  tier = 'gold',
  title,
  subtitle,
  size = 110,
  autoPlay = true,
  onComplete,
}) {
  const [isPlaying, setIsPlaying] = useState(autoPlay);
  const [isFinished, setIsFinished] = useState(false);

  useEffect(() => {
    if (isPlaying) {
      const timer = setTimeout(() => {
        setIsFinished(true);
        if (onComplete) onComplete();
      }, 1900); // 300ms delay + 700ms reveal + 900ms shine
      return () => clearTimeout(timer);
    }
  }, [isPlaying, onComplete]);

  const defaultTitles = {
    gold: 'Gold Badge Earned',
    silver: 'Silver Badge Earned',
    bronze: 'Bronze Badge Earned',
  };

  const defaultSubtitles = {
    gold: 'Flawless performance! Perfect lesson.',
    silver: 'Solid run! Great effort and accuracy.',
    bronze: 'Completed! Keep practicing to reach gold.',
  };

  const emojis = {
    gold: '🥇',
    silver: '🥈',
    bronze: '🥉',
  };

  const handleSkip = () => {
    setIsFinished(true);
    if (onComplete) onComplete();
  };

  return (
    <div className="badge-reveal-container" onClick={handleSkip} role="button" tabIndex={0}>
      {/* Gold Confetti Burst */}
      {tier === 'gold' && (
        <div className="badge-confetti-wrapper">
          <div className="badge-confetti-particle p1" />
          <div className="badge-confetti-particle p2" />
          <div className="badge-confetti-particle p3" />
          <div className="badge-confetti-particle p4" />
          <div className="badge-confetti-particle p5" />
          <div className="badge-confetti-particle p6" />
        </div>
      )}

      {/* 3D Reward Badge */}
      <div
        className={`badge-reveal-disc badge-reveal-disc--${tier} ${
          isFinished ? 'badge-reveal-disc--settled' : 'badge-reveal-disc--animating'
        }`}
        style={{ width: `${size}px`, height: `${size}px` }}
      >
        <div className="badge-reveal-inner">
          <span className="badge-reveal-icon">🏆</span>
        </div>
      </div>

      {/* Label Text Slide Up */}
      <div
        className={`badge-reveal-text ${
          isFinished ? 'badge-reveal-text--settled' : 'badge-reveal-text--animating'
        }`}
      >
        <h3 className="badge-reveal-title">{title || defaultTitles[tier]}</h3>
        <p className="badge-reveal-subtitle">{subtitle || defaultSubtitles[tier]}</p>
      </div>
    </div>
  );
}
