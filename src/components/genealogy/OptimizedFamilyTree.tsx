
import React, { useState, useRef, useEffect, useMemo, useCallback } from 'react';
import { Button } from '@/components/ui/button';
import { RotateCcw, ZoomIn, ZoomOut, Maximize2, Smartphone } from 'lucide-react';
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
  const [isMobile, setIsMobile] = useState(false);
  const [autoCenter, setAutoCenter] = useState(true);
  const containerRef = useRef<HTMLDivElement>(null);

  // Mobil tespiti
  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };
    
    checkMobile();
    window.addEventListener('resize', checkMobile);
    
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  // Simulate loading delay for large family trees
  useEffect(() => {
    const timer = setTimeout(() => setIsLoading(false), 300);
    return () => clearTimeout(timer);
  }, [selectedBird.id]);

  // Otomatik merkeze gelme
  useEffect(() => {
    if (autoCenter) {
      const timer = setTimeout(() => {
        setPanOffset({ x: 0, y: 0 });
        setScale(isMobile ? 0.6 : 0.8);
      }, 200);

      return () => clearTimeout(timer);
    }
  }, [selectedBird.id, autoCenter, isMobile]);

  // Otomatik merkeze gelme fonksiyonu
  const handleAutoCenter = useCallback(() => {
    setPanOffset({ x: 0, y: 0 });
    setScale(isMobile ? 0.6 : 0.8);
    setAutoCenter(true);
  }, [isMobile]);

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

    // Add grandparents (limit to avoid performance issues) - sadece desktop'ta göster
    if (!isMobile) {
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
    }

    // Add children (limit to first 12 for performance, with lazy loading)
    const maxChildren = isMobile ? (scale > 0.6 ? 6 : 4) : (scale > 0.6 ? 12 : 8); // Mobilde daha az çocuk göster
    familyData.children.slice(0, maxChildren).forEach((child, index) => {
      nodes.push({ bird: child, position: 'child', label: `Yavru ${index + 1}` });
    });

    return nodes;
  }, [selectedBird, familyData, scale, isMobile]); // Add isMobile dependency

  // Memoized canvas dimensions - mobil için optimize edilmiş
  const canvasConfig = useMemo(() => ({
    width: isMobile ? Math.min(window.innerWidth - 40, 400) : 1200,
    height: isMobile ? Math.min(window.innerHeight - 200, 600) : 800
  }), [isMobile]);

  // Optimized pan handlers with useCallback
  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    if (e.button !== 0) return;
    e.preventDefault();
    setIsDragging(true);
    setDragStart({ x: e.clientX - panOffset.x, y: e.clientY - panOffset.y });
    setAutoCenter(false); // Manuel pan yapıldığında auto center'ı kapat
  }, [panOffset]);

  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    if (!isDragging) return;
    e.preventDefault();
    setPanOffset({ x: e.clientX - dragStart.x, y: e.clientY - dragStart.y });
  }, [isDragging, dragStart]);

  const handleMouseUp = useCallback(() => setIsDragging(false), []);

  // Touch handlers with useCallback
  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    if (e.touches.length === 1) {
      e.preventDefault();
      setIsDragging(true);
      const touch = e.touches[0];
      if (touch) {
        setDragStart({ x: touch.clientX - panOffset.x, y: touch.clientY - panOffset.y });
        setAutoCenter(false);
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

  // Zoom handlers
  const handleZoomIn = useCallback(() => {
    const newScale = Math.min(scale * 1.2, 2);
    setScale(newScale);
    setAutoCenter(false);
  }, [scale]);

  const handleZoomOut = useCallback(() => {
    const newScale = Math.max(scale / 1.2, 0.3);
    setScale(newScale);
    setAutoCenter(false);
  }, [scale]);

  const handleReset = useCallback(() => {
    setScale(isMobile ? 0.6 : 0.8);
    setPanOffset({ x: 0, y: 0 });
    setAutoCenter(true);
  }, [isMobile]);

  // Wheel handler for zoom
  const handleWheel = useCallback((e: React.WheelEvent) => {
    e.preventDefault();
    const delta = e.deltaY > 0 ? -0.1 : 0.1;
    const newScale = Math.min(Math.max(scale + delta, 0.3), 2);
    setScale(newScale);
    setAutoCenter(false);
  }, [scale]);

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
      {/* Header with controls */}
      <div className="flex justify-between items-center mb-4">
        <div className="flex gap-2">
          <Button onClick={handleZoomIn} variant="outline" size="sm">
            <ZoomIn className="w-4 h-4" />
          </Button>
          <Button onClick={handleZoomOut} variant="outline" size="sm">
            <ZoomOut className="w-4 h-4" />
          </Button>
          <Button onClick={handleReset} variant="outline" size="sm">
            <RotateCcw className="w-4 h-4" />
          </Button>
          <Button 
            onClick={handleAutoCenter} 
            variant={autoCenter ? "default" : "outline"} 
            size="sm"
            className={autoCenter ? 'bg-purple-600 hover:bg-purple-700' : ''}
          >
            <Maximize2 className="w-4 h-4" />
          </Button>
        </div>
        <div className="text-sm enhanced-text-secondary flex items-center gap-2">
          {isMobile && <Smartphone className="w-4 h-4 text-blue-500" />}
          Zoom: {Math.round(scale * 100)}% | {visibleNodes.length} düğüm | ⚡ Optimized
        </div>
      </div>

      {/* Mobil uyarı */}
      {isMobile && (
        <div className="mb-3 p-2 bg-blue-50 border border-blue-200 rounded-lg text-xs text-blue-700">
          📱 <strong>Mobil Mod:</strong> Dokunmatik kaydırma aktif. Otomatik merkezleme açık.
        </div>
      )}

      {/* Optimized Tree Canvas */}
      <div 
        ref={containerRef}
        className={`relative w-full border-2 border-border rounded-lg overflow-hidden bg-muted/20 cursor-move select-none ${
          isMobile ? 'h-[400px]' : 'h-80 md:h-[500px]'
        }`}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
        onWheel={handleWheel}
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
        style={{ 
          willChange: 'transform',
          touchAction: 'none' // Touch scroll'u engelle
        }}
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
                  (node.label === 'Baba' ? (isMobile ? 150 : 400) : (isMobile ? 250 : 800)) : 
                  (isMobile ? (200 + (index * 50)) : (450 + (index * 100)));
                const y2 = node.position === 'parent' ? (isMobile ? 175 : 275) : (isMobile ? 350 : 550);
                
                return (
                  <line
                    key={`connection-${index}-${node.bird.id}`}
                    x1={isMobile ? 200 : 600}
                    y1={isMobile ? 200 : 400}
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
              let position: { left: string; top: string; } = { 
                left: isMobile ? '150px' : '550px', 
                top: isMobile ? '150px' : '350px' 
              }; // Default center
              
              if (node.position === 'parent') {
                position = node.label === 'Baba' ? 
                  { left: isMobile ? '50px' : '350px', top: isMobile ? '75px' : '225px' } : 
                  { left: isMobile ? '150px' : '750px', top: isMobile ? '75px' : '225px' };
              } else if (node.position === 'grandparent') {
                const positions = isMobile ? [
                  { left: '25px', top: '25px' },
                  { left: '125px', top: '25px' },
                  { left: '225px', top: '25px' },
                  { left: '325px', top: '25px' }
                ] : [
                  { left: '250px', top: '100px' },
                  { left: '450px', top: '100px' },
                  { left: '650px', top: '100px' },
                  { left: '850px', top: '100px' }
                ];
                position = positions[index] ? positions[index] : { left: isMobile ? '25px' : '250px', top: isMobile ? '25px' : '100px' };
              } else if (node.position === 'child') {
                position = { 
                  left: isMobile ? `${150 + (index * 50)}px` : `${400 + (index * 100)}px`, 
                  top: isMobile ? '300px' : '500px' 
                };
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
                    isMobile={isMobile}
                  />
                </div>
              );
            })}
          </div>
        </div>

        {/* Mobil kontroller overlay */}
        {isMobile && (
          <div className="absolute bottom-2 right-2 flex flex-col gap-1">
            <Button
              variant="outline"
              size="sm"
              onClick={handleAutoCenter}
              className={`h-8 w-8 p-0 ${autoCenter ? 'bg-purple-600 text-white' : ''}`}
            >
              <Maximize2 className="w-4 h-4" />
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={handleReset}
              className="h-8 w-8 p-0"
            >
              <RotateCcw className="w-4 h-4" />
            </Button>
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
