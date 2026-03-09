import React from 'react';
import { staticFile } from 'remotion';
import { PHONE } from '../config/constants';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';

type NavTab = 'home' | 'birds' | 'breeding' | 'calendar' | 'more';

interface PhoneNavBarProps {
  activeTab?: NavTab;
}

const tabs: { key: NavTab; label: string; icon: string }[] = [
  { key: 'home', label: 'Ana Sayfa', icon: 'home.svg' },
  { key: 'birds', label: 'Kuslar', icon: 'bird.svg' },
  { key: 'breeding', label: 'Ureme', icon: 'breeding.svg' },
  { key: 'calendar', label: 'Takvim', icon: 'calendar.svg' },
  { key: 'more', label: 'Daha', icon: 'more.svg' },
];

export const PhoneNavBar: React.FC<PhoneNavBarProps> = ({
  activeTab = 'home',
}) => {
  return (
    <div
      style={{
        position: 'absolute',
        bottom: 0,
        left: 0,
        width: PHONE.width,
        height: 64,
        background: '#FFFFFF',
        borderTop: '1px solid #E2E8F0',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-around',
        padding: '4px 8px 12px',
        zIndex: 5,
      }}
    >
      {tabs.map((tab) => {
        const isActive = tab.key === activeTab;
        return (
          <div
            key={tab.key}
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 2,
              opacity: isActive ? 1 : 0.5,
            }}
          >
            <img
              src={staticFile(`icons/${tab.icon}`)}
              style={{
                width: 22,
                height: 22,
                filter: isActive
                  ? 'none'
                  : 'grayscale(100%) brightness(0.6)',
              }}
            />
            <span
              style={{
                fontFamily,
                fontSize: 10,
                fontWeight: isActive ? 600 : 400,
                color: isActive ? colors.primary : colors.neutral500,
              }}
            >
              {tab.label}
            </span>
          </div>
        );
      })}

      {/* Home indicator line */}
      <div
        style={{
          position: 'absolute',
          bottom: 4,
          left: '50%',
          transform: 'translateX(-50%)',
          width: 100,
          height: 4,
          background: '#000',
          borderRadius: 2,
          opacity: 0.2,
        }}
      />
    </div>
  );
};
