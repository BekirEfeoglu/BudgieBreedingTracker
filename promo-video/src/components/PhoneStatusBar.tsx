import React from 'react';
import { PHONE } from '../config/constants';
import { fontFamily } from '../config/fonts';

interface PhoneStatusBarProps {
  time?: string;
  dark?: boolean;
}

export const PhoneStatusBar: React.FC<PhoneStatusBarProps> = ({
  time = '14:32',
  dark = false,
}) => {
  const color = dark ? '#FFFFFF' : '#000000';

  return (
    <div
      style={{
        width: PHONE.width,
        height: 54,
        display: 'flex',
        alignItems: 'flex-end',
        justifyContent: 'space-between',
        padding: '0 24px 6px',
        position: 'relative',
        zIndex: 5,
      }}
    >
      {/* Time */}
      <span
        style={{
          fontFamily,
          fontSize: 15,
          fontWeight: 600,
          color,
          letterSpacing: 0.2,
        }}
      >
        {time}
      </span>

      {/* Right icons: signal, wifi, battery */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        {/* Signal bars */}
        <svg width="17" height="12" viewBox="0 0 17 12" fill="none">
          <rect x="0" y="9" width="3" height="3" rx="0.5" fill={color} />
          <rect x="4.5" y="6" width="3" height="6" rx="0.5" fill={color} />
          <rect x="9" y="3" width="3" height="9" rx="0.5" fill={color} />
          <rect x="13.5" y="0" width="3" height="12" rx="0.5" fill={color} />
        </svg>

        {/* WiFi */}
        <svg width="16" height="12" viewBox="0 0 16 12" fill="none">
          <path
            d="M8 10.5a1.5 1.5 0 100 3 1.5 1.5 0 000-3z"
            fill={color}
            transform="translate(0,-2)"
          />
          <path
            d="M4.5 8.5C5.5 7 6.7 6.2 8 6.2s2.5.8 3.5 2.3"
            stroke={color}
            strokeWidth="1.5"
            strokeLinecap="round"
            fill="none"
            transform="translate(0,-2)"
          />
          <path
            d="M1.5 5.5C3.5 2.5 5.5 1 8 1s4.5 1.5 6.5 4.5"
            stroke={color}
            strokeWidth="1.5"
            strokeLinecap="round"
            fill="none"
            transform="translate(0,-2)"
          />
        </svg>

        {/* Battery */}
        <svg width="27" height="12" viewBox="0 0 27 12" fill="none">
          <rect
            x="0.5"
            y="0.5"
            width="22"
            height="11"
            rx="2.5"
            stroke={color}
            strokeWidth="1"
            fill="none"
            opacity="0.35"
          />
          <rect x="24" y="3.5" width="2" height="5" rx="1" fill={color} opacity="0.4" />
          <rect x="2" y="2" width="17" height="8" rx="1.5" fill={color} />
        </svg>
      </div>
    </div>
  );
};
