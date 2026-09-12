import React, { useEffect, useState } from 'react';

/**
 * Duolingo-style dynamic progress bar component.
 *
 * Props:
 * - value: number (0 - 100)
 * - height: number (default: 22)
 * - showLabel: boolean
 * - customLabel: string
 * - onMastery: callback when value reaches 100%
 */
export default function DuolingoProgressBar({
  value = 0,
  height = 22,
  showLabel = false,
  customLabel,
  onMastery,
}) {
  const clampedValue = Math.max(0, Math.min(100, Math.round(value)));
  const [pulseType, setPulseType] = useState(null); // 'correct' | 'mastery' | null
  const [prevValue, setPrevValue] = useState(clampedValue);

  useEffect(() => {
    if (clampedValue > prevValue) {
      if (clampedValue >= 100) {
        setPulseType('mastery');
        if (onMastery) onMastery();
      } else {
        setPulseType('correct');
      }
      const timer = setTimeout(() => {
        setPulseType(null);
      }, clampedValue >= 100 ? 700 : 500);
      return () => clearTimeout(timer);
    }
    setPrevValue(clampedValue);
  }, [clampedValue, prevValue, onMastery]);

  return (
    <div
      className={`duo-progress-track ${pulseType === 'mastery' ? 'duo-progress--mastery' : ''}`}
      style={{ height: `${height}px` }}
      role="progressbar"
      aria-valuenow={clampedValue}
      aria-valuemin="0"
      aria-valuemax="100"
      aria-label="Lesson progress"
    >
      <div
        className={`duo-progress-fill ${pulseType === 'correct' ? 'duo-progress--pulse-correct' : ''}`}
        style={{ width: `${clampedValue}%` }}
      />
      {showLabel && (
        <span className="duo-progress-label">
          {customLabel || `${clampedValue}%`}
        </span>
      )}
    </div>
  );
}
