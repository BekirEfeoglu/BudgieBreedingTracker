import React, { useState, useRef } from 'react';
import { Button } from '@/components/ui/button';
import { RotateCcw, ZoomIn, ZoomOut } from 'lucide-react';
import BirdNode from './BirdNode';
import { Bird, Chick } from '@/types';

interface FamilyData {
  father: Bird | Chick | null;
  mother: Bird | Chick | null;
  children: (Bird | Chick)[];
  grandparents: {
    paternalGrandfather: Bird | Chick | null;
    paternalGrandmother: Bird | Chick | null;
    maternalGrandfather: Bird | Chick | null;
    maternalGrandmother: Bird | Chick | null;
  };
}

interface FamilyTreeProps {
  selectedBird: Bird | Chick;
  familyData: FamilyData;
}

const FamilyTree = ({ selectedBird, familyData }: FamilyTreeProps) => {
  const [panOffset, setPanOffset] = useState({ x: 0, y: 0 });
  const [scale, setScale] = useState(0.8);
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const containerRef = useRef<HTMLDivElement>(null);
  const lastTouchRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });

  // Pan işlevleri
  const handleMouseDown = (e: React.MouseEvent) => {
    if (e.button !== 0) return; // Sadece sol tık
    setIsDragging(true);
    setDragStart({ x: e.clientX - panOffset.x, y: e.clientY - panOffset.y });
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging) return;
    setPanOffset({ x: e.clientX - dragStart.x, y: e.clientY - dragStart.y });
  };

  const handleMouseUp = () => {
    setIsDragging(false);
  };

  // Touch işlevleri
  const handleTouchStart = (e: React.TouchEvent) => {
    if (e.touches.length === 1) {
      const touch = e.touches[0];
      if (touch) {
        setIsDragging(true);
        setDragStart({ x: touch.clientX - panOffset.x, y: touch.clientY - panOffset.y });
      }
    }
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (!isDragging || e.touches.length !== 1) return;
    e.preventDefault();
    const touch = e.touches[0];
    if (!touch) return;
    const deltaX = touch.clientX - lastTouchRef.current.x;
    const deltaY = touch.clientY - lastTouchRef.current.y;
    setPanOffset({ x: panOffset.x + deltaX, y: panOffset.y + deltaY });
    lastTouchRef.current = { x: touch.clientX, y: touch.clientY };
  };

  const handleTouchEnd = () => {
    setIsDragging(false);
  };

  // Zoom işlevleri
  const handleWheel = (e: React.WheelEvent) => {
    e.preventDefault();
    const delta = e.deltaY > 0 ? -0.1 : 0.1;
    setScale(prev => Math.min(Math.max(prev + delta, 0.3), 2));
  };

  const zoomIn = () => setScale(prev => Math.min(prev + 0.1, 2));
  const zoomOut = () => setScale(prev => Math.max(prev - 0.1, 0.3));
  
  const resetView = () => {
    setScale(0.8);
    setPanOffset({ x: 0, y: 0 });
  };

  // Canvas boyutları
  const canvasWidth = 1200;
  const canvasHeight = 800;

  return (
    <div className="relative">
      {/* Kontroller */}
      <div className="flex justify-between items-center mb-4">
        <div className="flex gap-2">
          <Button onClick={zoomIn} variant="outline" size="sm">
            <ZoomIn className="w-4 h-4" />
          </Button>
          <Button onClick={zoomOut} variant="outline" size="sm">
            <ZoomOut className="w-4 h-4" />
          </Button>
          <Button onClick={resetView} variant="outline" size="sm">
            <RotateCcw className="w-4 h-4" />
          </Button>
        </div>
        <div className="text-sm enhanced-text-secondary">
          Zoom: {Math.round(scale * 100)}%
        </div>
      </div>

      {/* Soy Ağacı Canvas */}
      <div 
        ref={containerRef}
        className="relative w-full h-80 md:h-[500px] border-2 border-border rounded-lg overflow-hidden bg-muted/20 cursor-move select-none"
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
        onWheel={handleWheel}
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
      >
        <div
          className="absolute inset-0 transition-transform duration-200"
          style={{
            transform: `translate(${panOffset.x}px, ${panOffset.y}px) scale(${scale})`,
            transformOrigin: 'center center',
            width: canvasWidth,
            height: canvasHeight
          }}
        >
          <svg
            width={canvasWidth}
            height={canvasHeight}
            viewBox={`0 0 ${canvasWidth} ${canvasHeight}`}
            className="absolute inset-0"
          >
            {/* Büyükanne-Büyükbaba Bağlantıları */}
            {familyData.grandparents.paternalGrandfather && (
              <line x1="600" y1="400" x2="300" y2="150" stroke="hsl(var(--border))" strokeWidth="1" strokeDasharray="3,3" />
            )}
            {familyData.grandparents.paternalGrandmother && (
              <line x1="600" y1="400" x2="500" y2="150" stroke="hsl(var(--border))" strokeWidth="1" strokeDasharray="3,3" />
            )}
            {familyData.grandparents.maternalGrandfather && (
              <line x1="600" y1="400" x2="700" y2="150" stroke="hsl(var(--border))" strokeWidth="1" strokeDasharray="3,3" />
            )}
            {familyData.grandparents.maternalGrandmother && (
              <line x1="600" y1="400" x2="900" y2="150" stroke="hsl(var(--border))" strokeWidth="1" strokeDasharray="3,3" />
            )}

            {/* Anne-Baba Bağlantıları */}
            {familyData.father && (
              <line x1="600" y1="400" x2="400" y2="275" stroke="hsl(var(--border))" strokeWidth="2" strokeDasharray="5,5" />
            )}
            {familyData.mother && (
              <line x1="600" y1="400" x2="800" y2="275" stroke="hsl(var(--border))" strokeWidth="2" strokeDasharray="5,5" />
            )}

            {/* Yavru Bağlantıları */}
            {familyData.children.map((child, index) => (
              <line
                key={`child-line-${index}-${child.id}`}
                x1="600"
                y1="400"
                x2={450 + (index * 100)}
                y2="550"
                stroke="hsl(var(--border))"
                strokeWidth="2"
                strokeDasharray="5,5"
              />
            ))}
          </svg>

          {/* Kuş Düğümleri */}
          <div className="relative w-full h-full">
            {/* Büyükanne-Büyükbabalar */}
            {familyData.grandparents.paternalGrandfather && (
              <div className="absolute" style={{ left: '250px', top: '100px' }}>
                <BirdNode
                  bird={familyData.grandparents.paternalGrandfather}
                  position="grandparent"
                  label="Baba Tarafı Büyükbaba"
                />
              </div>
            )}
            {familyData.grandparents.paternalGrandmother && (
              <div className="absolute" style={{ left: '450px', top: '100px' }}>
                <BirdNode
                  bird={familyData.grandparents.paternalGrandmother}
                  position="grandparent"
                  label="Baba Tarafı Büyükanne"
                />
              </div>
            )}
            {familyData.grandparents.maternalGrandfather && (
              <div className="absolute" style={{ left: '650px', top: '100px' }}>
                <BirdNode
                  bird={familyData.grandparents.maternalGrandfather}
                  position="grandparent"
                  label="Anne Tarafı Büyükbaba"
                />
              </div>
            )}
            {familyData.grandparents.maternalGrandmother && (
              <div className="absolute" style={{ left: '850px', top: '100px' }}>
                <BirdNode
                  bird={familyData.grandparents.maternalGrandmother}
                  position="grandparent"
                  label="Anne Tarafı Büyükanne"
                />
              </div>
            )}

            {/* Seçili Kuş (Merkez) */}
            <div className="absolute" style={{ left: '550px', top: '350px' }}>
              <BirdNode
                bird={selectedBird}
                position="center"
                isSelected={true}
              />
            </div>

            {/* Baba */}
            {familyData.father && (
              <div className="absolute" style={{ left: '350px', top: '225px' }}>
                <BirdNode
                  bird={familyData.father}
                  position="parent"
                  label="Baba"
                />
              </div>
            )}

            {/* Anne */}
            {familyData.mother && (
              <div className="absolute" style={{ left: '750px', top: '225px' }}>
                <BirdNode
                  bird={familyData.mother}
                  position="parent"
                  label="Anne"
                />
              </div>
            )}

            {/* Yavrular */}
            {familyData.children.map((child, index) => (
              <div
                key={`child-node-${index}-${child.id}`}
                className="absolute"
                style={{ left: `${400 + (index * 100)}px`, top: '500px' }}
              >
                <BirdNode
                  bird={child}
                  position="child"
                  label={`Yavru ${index + 1}`}
                />
              </div>
            ))}
          </div>
        </div>

        {/* Aile Bilgisi Yok */}
        {!familyData.father && !familyData.mother && familyData.children.length === 0 && 
         !Object.values(familyData.grandparents).some(Boolean) && (
          <div className="absolute inset-0 flex items-center justify-center bg-muted/50 rounded-lg">
            <div className="text-center enhanced-text-secondary">
              <span className="text-4xl mb-4 block">👨‍👩‍👧‍👦</span>
              <h3 className="font-semibold mb-2 enhanced-text-primary text-base">
                Aile Bilgisi Bulunamadı
              </h3>
              <p className="text-sm">
                Bu kuş için anne, baba veya yavru bilgisi bulunmuyor.
              </p>
            </div>
          </div>
        )}
      </div>

      {/* Kullanım Ipuçları */}
      <div className="mt-2 text-xs enhanced-text-secondary text-center">
        Mouse tekerleği ile zoom, sürükle ile kaydır
      </div>
    </div>
  );
};

export default FamilyTree;
