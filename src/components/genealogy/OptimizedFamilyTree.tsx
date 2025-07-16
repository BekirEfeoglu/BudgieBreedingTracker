
import React, { useState, useRef, useEffect, useMemo, useCallback } from 'react';
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
  grandchildren: (Bird | Chick)[];
}

interface OptimizedFamilyTreeProps {
  selectedBird: Bird | Chick;
  familyData: FamilyData;
}

const OptimizedFamilyTree = React.memo(({ selectedBird, familyData }: OptimizedFamilyTreeProps) => {
  const [panOffset, setPanOffset] = useState({ x: 0, y: 0 });
  const [scale, setScale] = useState(0.8);
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const [isLoading, setIsLoading] = useState(true);
  const containerRef = useRef<HTMLDivElement>(null);

  // Simulate loading delay for large family trees
  useEffect(() => {
    const timer = setTimeout(() => setIsLoading(false), 300);
    return () => clearTimeout(timer);
  }, [selectedBird.id]);

  // Memoize visible nodes to prevent unnecessary re-renders
  const visibleNodes = useMemo(() => {
    const nodes = [];
    
    // Add selected bird (always visible)
    nodes.push({ bird: selectedBird, position: 'center', isSelected: true });

    // Add parents
    if (familyData.father) {
      nodes.push({ bird: familyData.father, position: 'parent', label: 'Baba' });
    }
    if (familyData.mother) {
      nodes.push({ bird: familyData.mother, position: 'parent', label: 'Anne' });
    }

    // Add grandparents (limit to avoid performance issues)
    const grandparentEntries = Object.entries(familyData.grandparents).slice(0, 4);
    grandparentEntries.forEach(([key, grandparent]) => {
      if (grandparent) {
        const labels: Record<string, string> = {
          paternalGrandfather: 'Baba Tarafı Büyükbaba',
          paternalGrandmother: 'Baba Tarafı Büyükanne',
          maternalGrandfather: 'Anne Tarafı Büyükbaba',
          maternalGrandmother: 'Anne Tarafı Büyükanne'
        };
        nodes.push({ bird: grandparent, position: 'grandparent', label: labels[key] });
      }
    });

    // Add children (limit to first 12 for performance, with lazy loading)
    const maxChildren = scale > 0.6 ? 12 : 8; // Show more children when zoomed in
    familyData.children.slice(0, maxChildren).forEach((child, index) => {
      nodes.push({ bird: child, position: 'child', label: `Yavru ${index + 1}` });
    });

    return nodes;
  }, [selectedBird, familyData, scale]); // Add scale dependency for adaptive rendering

  // Memoized canvas dimensions
  const canvasConfig = useMemo(() => ({
    width: 1200,
    height: 800
  }), []);

  // Optimized pan handlers with useCallback
  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    if (e.button !== 0) return;
    setIsDragging(true);
    setDragStart({ x: e.clientX - panOffset.x, y: e.clientY - panOffset.y });
  }, [panOffset]);

  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    if (!isDragging) return;
    setPanOffset({ x: e.clientX - dragStart.x, y: e.clientY - dragStart.y });
  }, [isDragging, dragStart]);

  const handleMouseUp = useCallback(() => setIsDragging(false), []);

  // Touch handlers with useCallback
  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    if (e.touches.length === 1) {
      const touch = e.touches[0];
      if (touch) {
        setIsDragging(true);
        setDragStart({ x: touch.clientX - panOffset.x, y: touch.clientY - panOffset.y });
      }
    }
  }, [panOffset]);

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    if (!isDragging || e.touches.length !== 1) return;
    e.preventDefault();
    const touch = e.touches[0];
    if (touch) {
      setPanOffset({ x: touch.clientX - dragStart.x, y: touch.clientY - dragStart.y });
    }
  }, [isDragging, dragStart]);

  const handleTouchEnd = useCallback(() => setIsDragging(false), []);

  // Zoom handlers with useCallback
  const handleWheel = useCallback((e: React.WheelEvent) => {
    e.preventDefault();
    const delta = e.deltaY > 0 ? -0.1 : 0.1;
    setScale(prev => Math.min(Math.max(prev + delta, 0.3), 2));
  }, []);

  const zoomIn = useCallback(() => setScale(prev => Math.min(prev + 0.1, 2)), []);
  const zoomOut = useCallback(() => setScale(prev => Math.max(prev - 0.1, 0.3)), []);
  
  const resetView = useCallback(() => {
    setScale(0.8);
    setPanOffset({ x: 0, y: 0 });
  }, []);

  // Memoized transform style
  const transformStyle = useMemo(() => ({
    transform: `translate(${panOffset.x}px, ${panOffset.y}px) scale(${scale})`,
    transformOrigin: 'center center',
    width: canvasConfig.width,
    height: canvasConfig.height
  }), [panOffset, scale, canvasConfig]);

  if (isLoading) {
    return (
      <div className="w-full h-80 md:h-[500px] border-2 border-border rounded-lg overflow-hidden bg-muted/20 flex items-center justify-center">
        <div className="text-center space-y-3">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
          <p className="text-sm enhanced-text-secondary">Soy ağacı yükleniyor...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="relative">
      {/* Controls */}
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
          Zoom: {Math.round(scale * 100)}% | {visibleNodes.length} düğüm | ⚡ Optimized
        </div>
      </div>

      {/* Optimized Tree Canvas */}
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
        style={{ willChange: 'transform' }}
      >
        <div
          className="absolute inset-0 transition-transform duration-100"
          style={transformStyle}
        >
          {/* Optimized SVG connections */}
          <svg
            width={canvasConfig.width}
            height={canvasConfig.height}
            viewBox={`0 0 ${canvasConfig.width} ${canvasConfig.height}`}
            className="absolute inset-0"
            style={{ pointerEvents: 'none' }}
          >
            {/* Only render visible connections */}
            {visibleNodes.map((node, index) => {
              if (node.position === 'parent' || node.position === 'child') {
                const x2 = node.position === 'parent' ? 
                  (node.label === 'Baba' ? 400 : 800) : 
                  (450 + (index * 100));
                const y2 = node.position === 'parent' ? 275 : 550;
                
                return (
                  <line
                    key={`connection-${index}-${node.bird.id}`}
                    x1="600"
                    y1="400"
                    x2={x2}
                    y2={y2}
                    stroke="hsl(var(--border))"
                    strokeWidth="2"
                    strokeDasharray="5,5"
                  />
                );
              }
              return null;
            })}
          </svg>

          {/* Optimized Bird Nodes */}
          <div className="relative w-full h-full">
            {visibleNodes.map((node, index) => {
              let position: { left: string; top: string; } = { left: '550px', top: '350px' }; // Default center
              
              if (node.position === 'parent') {
                position = node.label === 'Baba' ? 
                  { left: '350px', top: '225px' } : 
                  { left: '750px', top: '225px' };
              } else if (node.position === 'grandparent') {
                const positions = [
                  { left: '250px', top: '100px' },
                  { left: '450px', top: '100px' },
                  { left: '650px', top: '100px' },
                  { left: '850px', top: '100px' }
                ];
                position = positions[index] ? positions[index] : { left: '250px', top: '100px' };
              } else if (node.position === 'child') {
                position = { left: `${400 + (index * 100)}px`, top: '500px' };
              }

              return (
                <div
                  key={`node-${index}-${node.bird.id}`}
                  className="absolute"
                  style={position}
                >
                  <BirdNode
                    bird={node.bird}
                    position={node.position}
                    label={node.label || ''}
                    isSelected={node.isSelected || false}
                  />
                </div>
              );
            })}
          </div>
        </div>

        {/* No family data message */}
        {visibleNodes.length <= 1 && (
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

      {/* Usage hints with performance info */}
      <div className="mt-2 text-xs enhanced-text-secondary text-center">
        Mouse tekerleği ile zoom, sürükle ile kaydır • {visibleNodes.length} düğüm gösteriliyor
        {familyData.children.length > (scale > 0.6 ? 12 : 8) && (
          <span className="ml-2 text-orange-600">
            ({familyData.children.length - (scale > 0.6 ? 12 : 8)} yavru daha var - yakınlaştırın)
          </span>
        )}
        {familyData.children.length > 50 && (
          <span className="ml-2 text-red-600 font-medium">
            ⚠️ Çok büyük soy ağacı - performans etkilenebilir
          </span>
        )}
      </div>
    </div>
  );
});

OptimizedFamilyTree.displayName = 'OptimizedFamilyTree';

export default OptimizedFamilyTree;
