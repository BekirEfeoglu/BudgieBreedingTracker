import React from 'react';
import { interpolate } from 'remotion';
import { PHONE } from '../config/constants';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import type { Language } from '../i18n/types';

interface MockFamilyTreeProps {
  frame: number;
  lang: Language;
}

interface TreeNode {
  name: string;
  gender: 'male' | 'female';
  x: number;
  y: number;
  delay: number;
}

export const MockFamilyTree: React.FC<MockFamilyTreeProps> = ({ frame, lang }) => {
  const treeW = PHONE.width - 32;
  const centerX = treeW / 2;

  const nodes: TreeNode[] = [
    // Generation 0 (current bird)
    { name: 'Mavis', gender: 'male', x: centerX, y: 40, delay: 0 },
    // Generation 1 (parents)
    { name: 'Zeus', gender: 'male', x: centerX - 70, y: 130, delay: 20 },
    { name: 'Hera', gender: 'female', x: centerX + 70, y: 130, delay: 25 },
    // Generation 2 (grandparents)
    { name: 'Atlas', gender: 'male', x: centerX - 110, y: 220, delay: 45 },
    { name: 'Luna', gender: 'female', x: centerX - 35, y: 220, delay: 50 },
    { name: 'Ares', gender: 'male', x: centerX + 35, y: 220, delay: 55 },
    { name: 'Afrodit', gender: 'female', x: centerX + 110, y: 220, delay: 60 },
  ];

  // Connections: [fromIndex, toIndex]
  const connections: [number, number][] = [
    [0, 1], [0, 2],
    [1, 3], [1, 4],
    [2, 5], [2, 6],
  ];

  return (
    <div style={{
      width: PHONE.width, height: PHONE.height,
      background: colors.neutral50,
      padding: '54px 16px 64px', overflow: 'hidden',
    }}>
      <div style={{
        fontFamily, fontSize: 16, fontWeight: 700, color: colors.neutral900,
        marginBottom: 12, paddingTop: 4,
      }}>
        🌳 {lang === 'tr' ? 'Soy Agaci' : 'Family Tree'}
      </div>

      {/* Tree */}
      <div style={{
        position: 'relative', width: treeW, height: 300,
        background: colors.white, borderRadius: 14,
        border: `1px solid ${colors.neutral200}`,
        padding: '10px 0',
      }}>
        {/* SVG connections */}
        <svg style={{ position: 'absolute', top: 0, left: 0, width: treeW, height: 300, zIndex: 1 }}>
          {connections.map(([from, to], i) => {
            const fromNode = nodes[from];
            const toNode = nodes[to];
            const lineDelay = Math.max(fromNode.delay, toNode.delay) - 5;
            const lineProgress = interpolate(frame, [lineDelay, lineDelay + 20], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

            const x1 = fromNode.x;
            const y1 = fromNode.y + 22;
            const x2 = toNode.x;
            const y2 = toNode.y - 2;
            const midY = (y1 + y2) / 2;

            return (
              <path key={i}
                d={`M${x1},${y1} C${x1},${midY} ${x2},${midY} ${x2},${y2}`}
                fill="none"
                stroke={colors.primary}
                strokeWidth={2}
                strokeDasharray="200"
                strokeDashoffset={200 * (1 - lineProgress)}
                opacity={0.4}
              />
            );
          })}
        </svg>

        {/* Nodes */}
        {nodes.map((node, i) => {
          const nodeOpacity = interpolate(frame, [node.delay, node.delay + 15], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
          const nodeScale = interpolate(frame, [node.delay, node.delay + 15], [0.5, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
          const genderColor = node.gender === 'male' ? colors.genderMale : colors.genderFemale;
          const isRoot = i === 0;

          return (
            <div key={i} style={{
              position: 'absolute',
              left: node.x - 28,
              top: node.y - 12,
              width: 56,
              opacity: nodeOpacity,
              transform: `scale(${nodeScale})`,
              zIndex: 2,
              textAlign: 'center',
            }}>
              <div style={{
                width: isRoot ? 40 : 32,
                height: isRoot ? 40 : 32,
                borderRadius: '50%',
                background: `${genderColor}15`,
                border: `2px solid ${genderColor}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                margin: '0 auto 3px',
                fontSize: isRoot ? 16 : 13,
                boxShadow: isRoot ? `0 4px 12px ${genderColor}30` : 'none',
              }}>
                {node.gender === 'male' ? '♂' : '♀'}
              </div>
              <div style={{
                fontFamily, fontSize: isRoot ? 10 : 8,
                fontWeight: isRoot ? 700 : 500,
                color: colors.neutral800,
              }}>
                {node.name}
              </div>
            </div>
          );
        })}
      </div>

      {/* Legend */}
      <div style={{
        display: 'flex', justifyContent: 'center', gap: 16, marginTop: 12,
      }}>
        {[
          { label: lang === 'tr' ? 'Erkek' : 'Male', color: colors.genderMale },
          { label: lang === 'tr' ? 'Disi' : 'Female', color: colors.genderFemale },
        ].map((item, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <div style={{
              width: 10, height: 10, borderRadius: 5,
              background: item.color,
            }} />
            <span style={{ fontFamily, fontSize: 10, color: colors.neutral500 }}>
              {item.label}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};
