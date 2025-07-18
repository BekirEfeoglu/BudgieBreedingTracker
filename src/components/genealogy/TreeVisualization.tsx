import React, { useState, useCallback, useMemo, useRef, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Slider } from '@/components/ui/slider';
import { 
  ZoomIn, 
  ZoomOut, 
  RotateCcw
} from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Chick } from '@/types';

interface TreeNode {
  id: string;
  data: Bird | Chick;
  children: TreeNode[];
  level: number;
  position: { x: number; y: number };
  connections: { from: string; to: string }[];
}

interface TreeVisualizationProps {
  familyData: {
    father: Bird | Chick | null;
    mother: Bird | Chick | null;
    children: (Bird | Chick)[];
    grandparents: {
      paternalGrandfather: Bird | Chick | null;
      paternalGrandmother: Bird | Chick | null;
      maternalGrandfather: Bird | Chick | null;
      maternalGrandmother: Bird | Chick | null;
    };
    siblings: (Bird | Chick)[];
    cousins: (Bird | Chick)[];
  };
  selectedBird: Bird | Chick;
  onBirdSelect: (bird: Bird | Chick) => void;
}

const TreeVisualization: React.FC<TreeVisualizationProps> = ({
  familyData,
  selectedBird,
  onBirdSelect
}) => {
  const { t } = useLanguage();
  const containerRef = useRef<HTMLDivElement>(null);
  const [zoom, setZoom] = useState(1);
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const [showMiniMap, setShowMiniMap] = useState(false);
  const [showPerformanceInfo, setShowPerformanceInfo] = useState(false);

  // Renk kodlaması
  const getColorScheme = useCallback((bird: Bird | Chick) => {
    const colors = {
      gender: {
        male: '#3B82F6', // Mavi
        female: '#EC4899', // Pembe
        unknown: '#6B7280' // Gri
      },
      age: {
        young: '#10B981', // Yeşil (0-1 yaş)
        adult: '#F59E0B', // Turuncu (1-5 yaş)
        old: '#EF4444' // Kırmızı (5+ yaş)
      },
      health: {
        excellent: '#10B981', // Yeşil
        good: '#F59E0B', // Turuncu
        poor: '#EF4444', // Kırmızı
        unknown: '#6B7280' // Gri
      }
    };

    // Yaş hesaplama
    const birthDate = 'hatchDate' in bird ? bird.hatchDate : bird.birthDate;
    let ageCategory: 'young' | 'adult' | 'old' = 'young';
    if (birthDate) {
      const age = Math.floor((new Date().getTime() - new Date(birthDate).getTime()) / (1000 * 60 * 60 * 24));
      if (age < 365) ageCategory = 'young';
      else if (age < 1825) ageCategory = 'adult';
      else ageCategory = 'old';
    }

    // Sağlık durumu (varsayılan olarak good)
    const healthStatus = bird.healthNotes ? 'good' : 'unknown';

    return {
      gender: colors.gender[bird.gender] || colors.gender.unknown,
      age: colors.age[ageCategory],
      health: colors.health[healthStatus as keyof typeof colors.health],
      border: bird.id === selectedBird.id ? '#8B5CF6' : '#E5E7EB' // Seçili kuş için mor border
    };
  }, [selectedBird.id]);

  // Ağaç yapısını oluştur - Basitleştirilmiş versiyon
  const buildTreeStructure = useMemo(() => {
    const nodes: TreeNode[] = [];
    const connections: { from: string; to: string }[] = [];

    // Mobil için responsive container boyutları
    const isMobile = window.innerWidth < 768;
    const containerWidth = isMobile ? 400 : 1400;
    const containerHeight = isMobile ? 600 : 900;
    const centerX = containerWidth / 2;
    const centerY = containerHeight / 2;

    // Mobil için daha küçük mesafeler
    const spacing = isMobile ? 0.8 : 1.6;
    const parentDistance = isMobile ? 120 * spacing : 200 * spacing;
    const childDistance = isMobile ? 100 * spacing : 180 * spacing;

    // Sadece temel aile üyelerini göster
    const hasFather = !!familyData.father;
    const hasMother = !!familyData.mother;
    const childrenCount = Math.min(familyData.children.length, 3); // En fazla 3 çocuk göster

    // Seçili kuş (merkez) - daha büyük
    const centerNode: TreeNode = {
      id: selectedBird.id,
      data: selectedBird,
      children: [],
      level: 0,
      position: { x: centerX, y: centerY },
      connections: []
    };
    nodes.push(centerNode);

    // Ebeveynler (seviye -1) - sadece varsa göster
    if (hasFather) {
      const fatherNode: TreeNode = {
        id: familyData.father!.id,
        data: familyData.father!,
        children: [],
        level: -1,
        position: { x: centerX - parentDistance, y: centerY - parentDistance },
        connections: []
      };
      nodes.push(fatherNode);
      connections.push({ from: familyData.father!.id, to: selectedBird.id });
    }

    if (hasMother) {
      const motherNode: TreeNode = {
        id: familyData.mother!.id,
        data: familyData.mother!,
        children: [],
        level: -1,
        position: { x: centerX + parentDistance, y: centerY - parentDistance },
        connections: []
      };
      nodes.push(motherNode);
      connections.push({ from: familyData.mother!.id, to: selectedBird.id });
    }

    // Çocuklar (seviye 1) - sadece ilk 3'ü göster
    if (childrenCount > 0) {
      familyData.children.slice(0, 3).forEach((child, index) => {
        let x, y;
        
        if (childrenCount === 1) {
          // Tek çocuk varsa merkez altında
          x = centerX;
          y = centerY + childDistance;
        } else if (childrenCount === 2) {
          // İki çocuk varsa yan yana
          x = index === 0 ? centerX - childDistance * 0.6 : centerX + childDistance * 0.6;
          y = centerY + childDistance;
        } else {
          // Üç çocuk varsa üçgen dağılım
          const angle = (index * 2 * Math.PI / 3) - Math.PI / 2;
          const radius = childDistance * 0.8;
          x = centerX + Math.cos(angle) * radius;
          y = centerY + Math.sin(angle) * radius + childDistance;
        }
        
        const childNode: TreeNode = {
          id: child.id,
          data: child,
          children: [],
          level: 1,
          position: { x, y },
          connections: []
        };
        nodes.push(childNode);
        connections.push({ from: selectedBird.id, to: child.id });
      });
    }

    return { nodes, connections };
  }, [familyData, selectedBird]);

  // Otomatik merkeze gelme
  useEffect(() => {
    // Seçili kuş değiştiğinde otomatik olarak merkeze gel
    setTimeout(() => {
      setPan({ x: 0, y: 0 });
      setZoom(1);
    }, 100);
  }, [selectedBird.id]);

  // Zoom kontrolleri
  const handleZoomIn = useCallback(() => {
    const newZoom = Math.min(zoom * 1.2, 3);
    setZoom(newZoom);
  }, [zoom]);

  const handleZoomOut = useCallback(() => {
    const newZoom = Math.max(zoom / 1.2, 0.3);
    setZoom(newZoom);
  }, [zoom]);

  const handleReset = useCallback(() => {
    setZoom(1);
    setPan({ x: 0, y: 0 });
  }, []);

  // Pan kontrolleri - Mouse ve Touch uyumlu
  const handleMouseDown = useCallback((e: React.MouseEvent | React.TouchEvent) => {
    setIsDragging(true);
    const clientX = 'touches' in e && e.touches[0] ? e.touches[0].clientX : (e as React.MouseEvent).clientX;
    const clientY = 'touches' in e && e.touches[0] ? e.touches[0].clientY : (e as React.MouseEvent).clientY;
    setDragStart({ x: clientX - pan.x, y: clientY - pan.y });
  }, [pan]);

  const handleMouseMove = useCallback((e: React.MouseEvent | React.TouchEvent) => {
    if (isDragging) {
      const clientX = 'touches' in e && e.touches[0] ? e.touches[0].clientX : (e as React.MouseEvent).clientX;
      const clientY = 'touches' in e && e.touches[0] ? e.touches[0].clientY : (e as React.MouseEvent).clientY;
      setPan({
        x: clientX - dragStart.x,
        y: clientY - dragStart.y
      });
    }
  }, [isDragging, dragStart]);

  const handleMouseUp = useCallback(() => {
    setIsDragging(false);
  }, []);



  // Bağlantı çizgileri
  const renderConnections = useCallback(() => {
    return buildTreeStructure.connections.map((connection, index) => {
      const fromNode = buildTreeStructure.nodes.find(n => n.id === connection.from);
      const toNode = buildTreeStructure.nodes.find(n => n.id === connection.to);
      
      if (!fromNode || !toNode) return null;

      const x1 = fromNode.position.x;
      const y1 = fromNode.position.y;
      const x2 = toNode.position.x;
      const y2 = toNode.position.y;

      return (
        <svg
          key={`connection-${index}-${connection.from}-${connection.to}`}
          className="absolute inset-0 pointer-events-none"
          style={{ zIndex: 1 }}
        >
          <line
            x1={x1}
            y1={y1}
            x2={x2}
            y2={y2}
            stroke="#8B5CF6"
            strokeWidth="4"
            opacity="0.8"
          />
          {/* İkinci çizgi - daha kalın görünüm için */}
          <line
            x1={x1}
            y1={y1}
            x2={x2}
            y2={y2}
            stroke="#E5E7EB"
            strokeWidth="6"
            opacity="0.3"
          />
        </svg>
      );
    });
  }, [buildTreeStructure]);

  return (
    <Card className="enhanced-card">
      <CardHeader className="pb-4">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
          <CardTitle className="text-base md:text-lg flex items-center gap-2">
            🌳 {t('genealogy.treeVisualization')}
          </CardTitle>
          <div className="flex items-center gap-1 md:gap-2">
            {/* Basit zoom kontrolleri */}
            <Button
              variant="outline"
              size="sm"
              onClick={handleZoomOut}
              disabled={zoom <= 0.3}
              className="h-8 px-2"
            >
              <ZoomOut className="w-3 h-3 md:w-4 md:h-4" />
            </Button>
            <span className="text-xs md:text-sm font-mono min-w-[2.5rem] md:min-w-[3rem] text-center">
              {Math.round(zoom * 100)}%
            </span>
            <Button
              variant="outline"
              size="sm"
              onClick={handleZoomIn}
              disabled={zoom >= 3}
              className="h-8 px-2"
            >
              <ZoomIn className="w-3 h-3 md:w-4 md:h-4" />
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={handleReset}
              className="h-8 px-2"
            >
              <RotateCcw className="w-3 h-3 md:w-4 md:h-4" />
            </Button>
          </div>
        </div>
        
        {/* Renk kodlaması açıklaması */}
        <div className="flex flex-wrap gap-2 md:gap-4 text-xs text-muted-foreground mt-2">
          <div className="flex items-center gap-1">
            <div className="w-2 h-2 md:w-3 md:h-3 rounded-full bg-blue-500"></div>
            <span className="text-xs">Erkek</span>
          </div>
          <div className="flex items-center gap-1">
            <div className="w-2 h-2 md:w-3 md:h-3 rounded-full bg-pink-500"></div>
            <span className="text-xs">Dişi</span>
          </div>
          <div className="flex items-center gap-1">
            <div className="w-2 h-2 md:w-3 md:h-3 rounded-full bg-green-500"></div>
            <span className="text-xs">Genç</span>
          </div>
          <div className="flex items-center gap-1">
            <div className="w-2 h-2 md:w-3 md:h-3 rounded-full bg-orange-500"></div>
            <span className="text-xs">Yetişkin</span>
          </div>
          <div className="flex items-center gap-1">
            <div className="w-2 h-2 md:w-3 md:h-3 rounded-full bg-red-500"></div>
            <span className="text-xs">Yaşlı</span>
          </div>
        </div>
      </CardHeader>
      
      <CardContent>
        <div className="relative">
          {/* Ana ağaç container */}
          <div
            ref={containerRef}
            className="relative w-full h-[500px] md:h-[700px] lg:h-[900px] border border-dashed border-gray-300 rounded-lg overflow-hidden bg-gradient-to-br from-blue-50 to-green-50"
            style={{
              cursor: isDragging ? 'grabbing' : 'grab',
              touchAction: 'none' // Touch scroll'u engelle
            }}
            onMouseDown={handleMouseDown}
            onMouseMove={handleMouseMove}
            onMouseUp={handleMouseUp}
            onMouseLeave={handleMouseUp}
            onTouchStart={handleMouseDown}
            onTouchMove={handleMouseMove}
            onTouchEnd={handleMouseUp}
          >
            {/* Transform container */}
            <div 
              className="absolute inset-0 flex items-center justify-center"
              style={{
                transform: `translate(${pan.x}px, ${pan.y}px) scale(${zoom})`,
                transformOrigin: 'center center',
                transition: 'transform 0.3s ease-out'
              }}
            >
              {/* Bağlantı çizgileri */}
              {renderConnections()}
              
              {/* Kuş düğümleri */}
              {buildTreeStructure.nodes.map((node, index) => (
                <div
                  key={`node-${index}-${node.id}`}
                  className="absolute transform -translate-x-1/2 -translate-y-1/2 cursor-pointer"
                  style={{
                    left: `${node.position.x}px`,
                    top: `${node.position.y}px`,
                    zIndex: node.level + 10
                  }}
                  onClick={() => onBirdSelect(node.data)}
                >
                  <Card 
                    className={`w-28 h-32 md:w-36 md:h-40 lg:w-40 lg:h-44 transition-all duration-200 hover:scale-110 ${
                      node.id === selectedBird.id ? 'ring-2 md:ring-3 ring-purple-500 shadow-lg' : 'shadow-md'
                    }`}
                    style={{
                      borderColor: getColorScheme(node.data).border,
                      borderWidth: node.id === selectedBird.id ? '2px' : '1px'
                    }}
                  >
                    <CardContent className="p-2 md:p-3 lg:p-4">
                      <div className="flex flex-col items-center text-center h-full justify-between">
                        {/* Fotoğraf veya ikon */}
                        {node.data.photo ? (
                          <img 
                            src={node.data.photo} 
                            alt={node.data.name}
                            className="w-12 h-12 md:w-16 md:h-16 lg:w-18 lg:h-18 rounded-full object-cover mb-2 md:mb-3"
                          />
                        ) : (
                          <div 
                            className="w-12 h-12 md:w-16 md:h-16 lg:w-18 lg:h-18 rounded-full flex items-center justify-center text-lg md:text-xl lg:text-2xl mb-2 md:mb-3"
                            style={{ backgroundColor: getColorScheme(node.data).gender }}
                          >
                            {node.data.gender === 'male' ? '♂' : node.data.gender === 'female' ? '♀' : '?'}
                          </div>
                        )}
                        
                        {/* İsim - daha büyük ve net */}
                        <div className="flex-1 flex flex-col justify-center min-h-0">
                          <p className="text-xs md:text-sm lg:text-base font-semibold break-words w-full leading-tight mb-1 md:mb-2 line-clamp-2">
                            {node.data.name}
                          </p>
                          
                          {/* Yaş badge - daha büyük */}
                          {'hatchDate' in node.data || 'birthDate' in node.data ? (
                            <Badge 
                              variant="secondary" 
                              className="text-xs px-1 py-0.5 md:px-2 md:py-1"
                              style={{ backgroundColor: getColorScheme(node.data).age, color: 'white' }}
                            >
                              {/* Yaş hesaplama */}
                              {(() => {
                                const birthDate = 'hatchDate' in node.data ? node.data.hatchDate : node.data.birthDate;
                                if (!birthDate) return null;
                                const age = Math.floor((new Date().getTime() - new Date(birthDate).getTime()) / (1000 * 60 * 60 * 24));
                                if (age < 30) return `${age}g`;
                                if (age < 365) return `${Math.floor(age/30)}a`;
                                return `${Math.floor(age/365)}y`;
                              })()}
                            </Badge>
                          ) : null}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Zoom slider */}
        <div className="mt-4">
          <div className="flex items-center gap-2 mb-2">
            <ZoomOut className="w-4 h-4 text-muted-foreground" />
            <Slider
              value={[zoom]}
              onValueChange={([value]) => {
                const newZoom = value || 1;
                setZoom(newZoom);
              }}
              min={0.3}
              max={3}
              step={0.1}
              className="flex-1"
            />
            <ZoomIn className="w-4 h-4 text-muted-foreground" />
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default TreeVisualization; 