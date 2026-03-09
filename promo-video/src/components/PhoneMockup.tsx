import React from 'react';
import { PHONE } from '../config/constants';

interface PhoneMockupProps {
  children: React.ReactNode;
  scale?: number;
  style?: React.CSSProperties;
}

export const PhoneMockup: React.FC<PhoneMockupProps> = ({
  children,
  scale = 1,
  style,
}) => {
  const outerWidth = PHONE.width + PHONE.bezel * 2;
  const outerHeight = PHONE.height + PHONE.bezel * 2;

  return (
    <div
      style={{
        width: outerWidth,
        height: outerHeight,
        borderRadius: PHONE.borderRadius,
        background: '#1a1a1a',
        boxShadow:
          '0 25px 80px rgba(0,0,0,0.35), 0 10px 30px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.1)',
        padding: PHONE.bezel,
        position: 'relative',
        transform: `scale(${scale})`,
        transformOrigin: 'top center',
        ...style,
      }}
    >
      {/* Screen area */}
      <div
        style={{
          width: PHONE.width,
          height: PHONE.height,
          borderRadius: PHONE.screenBorderRadius,
          overflow: 'hidden',
          background: '#F8FAFC',
          position: 'relative',
        }}
      >
        {/* Dynamic Island / Notch */}
        <div
          style={{
            position: 'absolute',
            top: 10,
            left: '50%',
            transform: 'translateX(-50%)',
            width: PHONE.notchWidth,
            height: PHONE.notchHeight,
            background: '#1a1a1a',
            borderRadius: 20,
            zIndex: 10,
          }}
        />
        {children}
      </div>

      {/* Side button (power) */}
      <div
        style={{
          position: 'absolute',
          right: -3,
          top: 120,
          width: 3,
          height: 40,
          background: '#333',
          borderRadius: '0 2px 2px 0',
        }}
      />
      {/* Volume buttons */}
      <div
        style={{
          position: 'absolute',
          left: -3,
          top: 100,
          width: 3,
          height: 28,
          background: '#333',
          borderRadius: '2px 0 0 2px',
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: -3,
          top: 140,
          width: 3,
          height: 28,
          background: '#333',
          borderRadius: '2px 0 0 2px',
        }}
      />
    </div>
  );
};
