import React, { useState, useRef, useEffect } from 'react';
import '../styles/slide-captcha.css';

export default function SlideCaptcha({ onSuccess, onFail }) {
  const [isDragging, setIsDragging] = useState(false);
  const [position, setPosition] = useState(0);
  const [verified, setVerified] = useState(false);
  const [failed, setFailed] = useState(false);
  const sliderRef = useRef(null);
  const containerRef = useRef(null);
  const targetPosition = useRef(Math.random() * 60 + 20);

  useEffect(() => {
    if (verified) {
      setTimeout(() => onSuccess?.(), 300);
    }
  }, [verified, onSuccess]);

  const handleStart = (clientX) => {
    if (verified || failed) return;
    setIsDragging(true);
  };

  const handleMove = (clientX) => {
    if (!isDragging || verified || failed) return;

    const container = containerRef.current;
    if (!container) return;

    const rect = container.getBoundingClientRect();
    const maxPosition = rect.width - 50;
    let newPosition = clientX - rect.left - 25;

    newPosition = Math.max(0, Math.min(newPosition, maxPosition));
    setPosition(newPosition);
  };

  const handleEnd = () => {
    if (!isDragging || verified || failed) return;
    setIsDragging(false);

    const container = containerRef.current;
    if (!container) return;

    const rect = container.getBoundingClientRect();
    const maxPosition = rect.width - 50;
    const targetPixels = (targetPosition.current / 100) * maxPosition;
    const tolerance = 15;

    if (Math.abs(position - targetPixels) < tolerance) {
      setVerified(true);
      setPosition(targetPixels);
    } else {
      setFailed(true);
      onFail?.();
      setTimeout(() => {
        setPosition(0);
        setFailed(false);
        targetPosition.current = Math.random() * 60 + 20;
      }, 1000);
    }
  };

  const handleMouseMove = (e) => handleMove(e.clientX);
  const handleTouchMove = (e) => handleMove(e.touches[0].clientX);

  useEffect(() => {
    if (isDragging) {
      document.addEventListener('mousemove', handleMouseMove);
      document.addEventListener('mouseup', handleEnd);
      document.addEventListener('touchmove', handleTouchMove);
      document.addEventListener('touchend', handleEnd);

      return () => {
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleEnd);
        document.removeEventListener('touchmove', handleTouchMove);
        document.removeEventListener('touchend', handleEnd);
      };
    }
  }, [isDragging, position]);

  return (
    <div className="slide-captcha">
      <div
        ref={containerRef}
        className={`captcha-track ${verified ? 'verified' : ''} ${failed ? 'failed' : ''}`}
      >
        <div
          className="captcha-target"
          style={{ left: `${targetPosition.current}%` }}
        />
        <div
          className="captcha-progress"
          style={{ width: `${position}px` }}
        />
        <div
          ref={sliderRef}
          className={`captcha-slider ${isDragging ? 'dragging' : ''}`}
          style={{ left: `${position}px` }}
          onMouseDown={(e) => handleStart(e.clientX)}
          onTouchStart={(e) => handleStart(e.touches[0].clientX)}
        >
          {verified ? (
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
              <polyline points="20 6 9 17 4 12" />
            </svg>
          ) : failed ? (
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
              <line x1="18" y1="6" x2="6" y2="18" />
              <line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          ) : (
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          )}
        </div>
        <span className="captcha-text">
          {verified ? 'Verified!' : failed ? 'Try again' : 'Slide to verify'}
        </span>
      </div>
    </div>
  );
}
