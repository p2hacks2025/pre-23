import { useState, useEffect } from 'react';
import { Memory } from '../App';
import { Item, Rarity } from '../types/game';
import { Sparkles } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

interface DiggingGameProps {
  undiscoveredMemories: Memory[];
  onDiscover: (memory: Memory) => void;
  onDiscoverItem: (item: Item) => void;
  dailyDigs: number;
  setDailyDigs: (digs: number | ((prev: number) => number)) => void;
}

// Item pool with rarities and types
const ITEM_POOL = [
  // Gems (25% chance)
  { type: 'gem' as const, name: 'サファイア', description: '凍土に眠る青い宝石', rarity: 'common' as Rarity, image: 'https://images.unsplash.com/photo-1667419941709-7db68fe7828f?w=800', weight: 12 },
  { type: 'gem' as const, name: 'ルビー', description: '炎のような赤い宝石', rarity: 'rare' as Rarity, image: 'https://images.unsplash.com/photo-1667419941709-7db68fe7828f?w=800', weight: 8 },
  { type: 'gem' as const, name: 'エメラルド', description: '深緑に輝く希少な宝石', rarity: 'epic' as Rarity, image: 'https://images.unsplash.com/photo-1667419941709-7db68fe7828f?w=800', weight: 5 },
  
  // Beer Barrels (rare - total weight: 4.5)
  { type: 'barrel' as const, name: 'オーク樽', description: '古代の醸造所で使われた樽', rarity: 'rare' as Rarity, image: 'https://images.unsplash.com/photo-1675857945158-983ce2041a99?w=800', weight: 3 },
  { type: 'barrel' as const, name: 'ゴールデン樽', description: '黄金に輝く伝説の樽', rarity: 'epic' as Rarity, image: 'https://images.unsplash.com/photo-1675857945158-983ce2041a99?w=800', weight: 1 },
  { type: 'barrel' as const, name: '永久凍土の樽', description: '凍りついた古代のビール樽', rarity: 'epic' as Rarity, image: 'https://images.unsplash.com/photo-1675857945158-983ce2041a99?w=800', weight: 0.5 },
  
  // Beer Bottles (rare - total weight: 4.5)
  { type: 'bottle' as const, name: '古代ビール瓶', description: '封印されたクラフトビール', rarity: 'rare' as Rarity, image: 'https://images.unsplash.com/photo-1703564803569-2a9063d5cf06?w=800', weight: 3 },
  { type: 'bottle' as const, name: 'アイスビール瓶', description: '氷の結晶が入った幻のビール', rarity: 'epic' as Rarity, image: 'https://images.unsplash.com/photo-1703564803569-2a9063d5cf06?w=800', weight: 1 },
  { type: 'bottle' as const, name: '神秘のエール', description: 'オーロラ色に輝くビール', rarity: 'epic' as Rarity, image: 'https://images.unsplash.com/photo-1703564803569-2a9063d5cf06?w=800', weight: 0.5 },
  
  // Beer Glasses (very rare - total weight: 2.5)
  { type: 'glass' as const, name: 'フロストグラス', description: '永遠に冷たいビールグラス', rarity: 'rare' as Rarity, image: 'https://images.unsplash.com/photo-1700481443949-7010cbe0fa1b?w=800', weight: 2 },
  { type: 'glass' as const, name: '水晶のジョッキ', description: '透き通った美しいグラス', rarity: 'epic' as Rarity, image: 'https://images.unsplash.com/photo-1700481443949-7010cbe0fa1b?w=800', weight: 0.5 },
  
  // Legendary items (extremely rare - total weight: 0.4)
  { type: 'barrel' as const, name: '伝説の醸造樽', description: '神々が使った究極の樽', rarity: 'legendary' as Rarity, image: 'https://images.unsplash.com/photo-1675857945158-983ce2041a99?w=800', weight: 0.2 },
  { type: 'gem' as const, name: 'エターナルダイヤ', description: '永久凍土の心臓', rarity: 'legendary' as Rarity, image: 'https://images.unsplash.com/photo-1667419941709-7db68fe7828f?w=800', weight: 0.2 },
];

// Pixel patterns for each item type (16x12 grid, centered)
const PIXEL_PATTERNS: Record<string, Set<string>> = {
  // Barrel pattern (8x6 centered)
  barrel: new Set([
    '4,3', '5,3', '6,3', '7,3', '8,3', '9,3', '10,3', '11,3',
    '3,4', '4,4', '5,4', '6,4', '7,4', '8,4', '9,4', '10,4', '11,4', '12,4',
    '3,5', '4,5', '5,5', '6,5', '7,5', '8,5', '9,5', '10,5', '11,5', '12,5',
    '3,6', '4,6', '5,6', '6,6', '7,6', '8,6', '9,6', '10,6', '11,6', '12,6',
    '3,7', '4,7', '5,7', '6,7', '7,7', '8,7', '9,7', '10,7', '11,7', '12,7',
    '4,8', '5,8', '6,8', '7,8', '8,8', '9,8', '10,8', '11,8',
  ]),
  // Bottle pattern (4x8 centered)
  bottle: new Set([
    '7,2', '8,2',
    '7,3', '8,3',
    '6,4', '7,4', '8,4', '9,4',
    '6,5', '7,5', '8,5', '9,5',
    '6,6', '7,6', '8,6', '9,6',
    '6,7', '7,7', '8,7', '9,7',
    '6,8', '7,8', '8,8', '9,8',
    '6,9', '7,9', '8,9', '9,9',
  ]),
  // Glass pattern (5x6 centered)
  glass: new Set([
    '6,4', '7,4', '8,4', '9,4',
    '5,5', '6,5', '7,5', '8,5', '9,5', '10,5',
    '5,6', '6,6', '7,6', '8,6', '9,6', '10,6',
    '5,7', '6,7', '7,7', '8,7', '9,7', '10,7',
    '6,8', '7,8', '8,8', '9,8',
    '6,9', '7,9', '8,9', '9,9',
  ]),
  // Gem pattern (diamond shape)
  gem: new Set([
    '7,3', '8,3',
    '6,4', '7,4', '8,4', '9,4',
    '5,5', '6,5', '7,5', '8,5', '9,5', '10,5',
    '5,6', '6,6', '7,6', '8,6', '9,6', '10,6',
    '6,7', '7,7', '8,7', '9,7',
    '7,8', '8,8',
  ]),
  // Photo pattern (rectangle frame)
  memory: new Set([
    '4,3', '5,3', '6,3', '7,3', '8,3', '9,3', '10,3', '11,3',
    '4,4', '5,4', '10,4', '11,4',
    '4,5', '5,5', '10,5', '11,5',
    '4,6', '5,6', '10,6', '11,6',
    '4,7', '5,7', '10,7', '11,7',
    '4,8', '5,8', '6,8', '7,8', '8,8', '9,8', '10,8', '11,8',
  ]),
  // Nothing pattern (empty)
  nothing: new Set(),
};

// Colors for each item type
const PIXEL_COLORS: Record<string, string> = {
  barrel: 'bg-amber-700',
  bottle: 'bg-emerald-600',
  glass: 'bg-blue-400',
  gem: 'bg-purple-500',
  memory: 'bg-pink-500',
  nothing: 'bg-transparent',
};

// Boost effects based on rarity
interface BoostEffect {
  clicksRequired: number;
  bonusDigs: number;
  label: string;
  description: string;
}

const RARITY_BOOSTS: Record<Rarity, BoostEffect> = {
  common: {
    clicksRequired: 10,
    bonusDigs: 0,
    label: 'なし',
    description: 'ブースト効果なし',
  },
  rare: {
    clicksRequired: 8,
    bonusDigs: 0,
    label: '軽減',
    description: '次回の発掘が8回クリックで可能',
  },
  epic: {
    clicksRequired: 6,
    bonusDigs: 1,
    label: '大幅軽減',
    description: '次回の発掘が6回クリックで可能 + ボーナス発掘1回',
  },
  legendary: {
    clicksRequired: 3,
    bonusDigs: 2,
    label: '超ブースト',
    description: '次回の発掘が3回クリックで可能 + ボーナス発掘2回',
  },
};

export function DiggingGame({ undiscoveredMemories, onDiscover, onDiscoverItem, dailyDigs, setDailyDigs }: DiggingGameProps) {
  const [isDigging, setIsDigging] = useState(false);
  const [progress, setProgress] = useState(0);
  const [discoveredItem, setDiscoveredItem] = useState<Item | Memory | null>(null);
  const [clicks, setClicks] = useState(0);
  const [dugCells, setDugCells] = useState<Set<string>>(new Set());
  const [foundNothing, setFoundNothing] = useState(false);
  const [hiddenItemType, setHiddenItemType] = useState<string>('nothing');
  const [showIceBreak, setShowIceBreak] = useState(false);
  const [clickEffects, setClickEffects] = useState<Array<{ id: string; x: number; y: number }>>([]);
  const [activeBoost, setActiveBoost] = useState<BoostEffect | null>(null);
  const [bonusDigsRemaining, setBonusDigsRemaining] = useState(0);
  const [showBoostNotification, setShowBoostNotification] = useState(false);

  const getRandomItem = (): Item | Memory | null => {
    // 40% chance to find nothing
    if (Math.random() < 0.4) {
      return null;
    }

    // 30% chance to get a memory if available (out of remaining 60%)
    if (undiscoveredMemories.length > 0 && Math.random() < 0.5) {
      const randomIndex = Math.floor(Math.random() * undiscoveredMemories.length);
      return undiscoveredMemories[randomIndex];
    }

    // Otherwise, get a random item based on weights
    const totalWeight = ITEM_POOL.reduce((sum, item) => sum + item.weight, 0);
    let random = Math.random() * totalWeight;

    for (const itemData of ITEM_POOL) {
      random -= itemData.weight;
      if (random <= 0) {
        return {
          id: Date.now().toString() + Math.random(),
          type: itemData.type,
          name: itemData.name,
          description: itemData.description,
          rarity: itemData.rarity,
          image: itemData.image,
          discoveredAt: new Date(),
        };
      }
    }

    // Fallback (should rarely happen)
    return null;
  };

  // Initialize hidden item type when component mounts or resets
  useEffect(() => {
    const item = getRandomItem();
    if (item === null) {
      setHiddenItemType('nothing');
    } else if ('photo' in item) {
      setHiddenItemType('memory');
    } else {
      setHiddenItemType((item as Item).type);
    }
  }, [clicks === 0]); // Reset when clicks is 0

  useEffect(() => {
    if (isDigging) {
      const interval = setInterval(() => {
        setProgress((prev) => {
          if (prev >= 100) {
            clearInterval(interval);
            
            // Trigger ice break animation
            setShowIceBreak(true);
            
            // Wait for animation to complete before showing result
            setTimeout(() => {
              const item = getRandomItem();
              
              if (item === null) {
                // Found nothing
                setFoundNothing(true);
                setDiscoveredItem(null);
              } else {
                setFoundNothing(false);
                setDiscoveredItem(item);
                
                // Check if it's a Memory or Item
                if ('photo' in item) {
                  onDiscover(item as Memory);
                } else {
                  onDiscoverItem(item as Item);
                }
              }
              
              setShowIceBreak(false);
            }, 1200); // Animation duration
            
            return 100;
          }
          return prev + 2;
        });
      }, 50);

      return () => clearInterval(interval);
    }
  }, [isDigging]);

  const handleDig = (x: number, y: number) => {
    if (isDigging || discoveredItem || foundNothing) return;

    const requiredClicks = activeBoost?.clicksRequired || 10;
    setClicks(prev => {
      const newClicks = prev + 1;
      if (newClicks >= requiredClicks) {
        setIsDigging(true);
      }
      return newClicks;
    });
  };

  const handleReset = () => {
    // Consume one daily dig when completing
    if (!foundNothing && discoveredItem) {
      setDailyDigs(prev => Math.max(0, prev - 1));
    }
    
    // Check if we discovered an item and apply boost
    if (discoveredItem && !('photo' in discoveredItem)) {
      const item = discoveredItem as Item;
      const boost = RARITY_BOOSTS[item.rarity];
      
      if (boost.clicksRequired < 10 || boost.bonusDigs > 0) {
        setActiveBoost(boost);
        setBonusDigsRemaining(prev => prev + boost.bonusDigs);
        setShowBoostNotification(true);
        setTimeout(() => setShowBoostNotification(false), 3000);
      }
    }
    
    // If bonus digs remain, decrement counter
    if (bonusDigsRemaining > 0) {
      setBonusDigsRemaining(prev => prev - 1);
    }
    
    // Clear boost if no more bonus digs and not a rare+ item
    if (bonusDigsRemaining === 0 && activeBoost && activeBoost.clicksRequired === 10) {
      setActiveBoost(null);
    }
    
    setIsDigging(false);
    setProgress(0);
    setDiscoveredItem(null);
    setClicks(0);
    setDugCells(new Set());
    setFoundNothing(false);
    setShowIceBreak(false);
    setClickEffects([]);
  };

  const rarityColors = {
    common: 'from-gray-400 to-gray-600',
    rare: 'from-blue-400 to-blue-600',
    epic: 'from-purple-400 to-purple-600',
    legendary: 'from-amber-400 to-orange-600',
  };

  const rarityLabels = {
    common: 'コモン',
    rare: 'レア',
    epic: 'エピック',
    legendary: 'レジェンダリー',
  };

  // Pixel art grid (16x12 cells)
  const GRID_WIDTH = 16;
  const GRID_HEIGHT = 12;

  const handleCellClick = (cellX: number, cellY: number) => {
    if (isDigging || discoveredItem || foundNothing) return;

    const key = `${cellX},${cellY}`;
    if (!dugCells.has(key)) {
      setDugCells(new Set([...dugCells, key]));
      
      // Add click effect
      const effectId = `effect-${Date.now()}-${Math.random()}`;
      const gridElement = document.querySelector(`[data-cell="${key}"]`);
      if (gridElement) {
        const rect = gridElement.getBoundingClientRect();
        const containerRect = gridElement.closest('.grid')?.getBoundingClientRect();
        if (containerRect) {
          const relativeX = rect.left - containerRect.left + rect.width / 2;
          const relativeY = rect.top - containerRect.top + rect.height / 2;
          setClickEffects(prev => [...prev, { id: effectId, x: relativeX, y: relativeY }]);
          
          // Remove effect after animation completes
          setTimeout(() => {
            setClickEffects(prev => prev.filter(e => e.id !== effectId));
          }, 800);
        }
      }
      
      handleDig(cellX, cellY);
    }
  };

  return (
    <div className="max-w-2xl mx-auto">
      {/* Out of digs notification */}
      {dailyDigs === 0 && bonusDigsRemaining === 0 && (
        <div className="bg-gradient-to-br from-cyan-900/40 to-blue-900/40 backdrop-blur-md rounded-2xl p-8 shadow-xl border border-cyan-400/30 text-center">
          <div className="text-6xl mb-4">⏰</div>
          <h2 className="text-2xl mb-4 text-cyan-100">本日の発掘回数を使い切りました</h2>
          <p className="text-cyan-300/80 mb-6">
            デイリー発掘は明日リセットされます。<br />
            レアアイテムのボーナス発掘で追加チャンスを手に入れましょう！
          </p>
          <div className="flex items-center justify-center gap-2 text-cyan-200">
            <Sparkles className="w-5 h-5" />
            <span>明日の発掘をお楽しみに</span>
            <Sparkles className="w-5 h-5" />
          </div>
        </div>
      )}

      {/* Boost Notification */}
      <AnimatePresence>
        {showBoostNotification && activeBoost && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="mb-4 bg-gradient-to-r from-amber-500/20 to-orange-500/20 backdrop-blur-md border-2 border-amber-400/50 rounded-xl p-4 shadow-lg"
          >
            <div className="flex items-center gap-3">
              <Sparkles className="w-6 h-6 text-amber-400 animate-pulse" />
              <div className="flex-1">
                <p className="text-amber-100 mb-1">🎉 ブースト獲得！</p>
                <p className="text-amber-200/80 text-sm">{activeBoost.description}</p>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Active Boost Display */}
      {activeBoost && !discoveredItem && !foundNothing && (
        <div className="mb-4 bg-gradient-to-r from-purple-900/30 to-blue-900/30 backdrop-blur-md border border-purple-400/30 rounded-xl p-3 shadow-lg">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-purple-300" />
              <span className="text-purple-100">アクティブブースト: {activeBoost.label}</span>
            </div>
            {bonusDigsRemaining > 0 && (
              <span className="px-3 py-1 bg-purple-500/30 rounded-full text-purple-100 text-sm">
                ボーナス発掘: {bonusDigsRemaining}回
              </span>
            )}
          </div>
        </div>
      )}

      {!discoveredItem && !foundNothing ? (
        <div className="bg-gradient-to-br from-cyan-900/40 to-blue-900/40 backdrop-blur-md rounded-2xl p-6 shadow-xl border border-cyan-400/30 relative">
          <h2 className="text-2xl mb-4 text-center text-cyan-100">永久凍土を掘り起こせ</h2>
          <p className="text-center text-cyan-200 mb-6">
            {clicks < (activeBoost?.clicksRequired || 10) 
              ? `凍土をクリックして掘ってください（あと${(activeBoost?.clicksRequired || 10) - clicks}回）` 
              : '掘削中...'}
          </p>

          {/* Pixel Art Digging Area */}
          <div className="relative w-full bg-gradient-to-b from-cyan-950 to-blue-950 rounded-xl overflow-hidden shadow-inner border-2 border-cyan-300/50">
            <div 
              className="grid gap-0"
              style={{
                gridTemplateColumns: `repeat(${GRID_WIDTH}, 1fr)`,
                gridTemplateRows: `repeat(${GRID_HEIGHT}, 1fr)`,
                aspectRatio: `${GRID_WIDTH} / ${GRID_HEIGHT}`,
              }}
            >
              {Array.from({ length: GRID_HEIGHT }).map((_, y) =>
                Array.from({ length: GRID_WIDTH }).map((_, x) => {
                  const key = `${x},${y}`;
                  const isDug = dugCells.has(key);
                  const isPartOfHiddenItem = PIXEL_PATTERNS[hiddenItemType]?.has(key) || false;
                  
                  return (
                    <div
                      key={key}
                      onClick={() => handleCellClick(x, y)}
                      className={`cursor-pointer transition-all duration-200 border border-cyan-800/20 relative ${
                        isDug
                          ? 'bg-gradient-to-br from-cyan-900 to-blue-950'
                          : 'bg-gradient-to-br from-cyan-200 via-blue-300 to-cyan-400 hover:brightness-110'
                      }`}
                      style={{
                        boxShadow: isDug ? 'inset 0 2px 4px rgba(0,0,0,0.3)' : 'none',
                      }}
                      data-cell={key}
                    >
                      {/* Hidden item pixel underneath */}
                      {isPartOfHiddenItem && (
                        <div className={`absolute inset-0 ${PIXEL_COLORS[hiddenItemType]} ${isDug ? 'opacity-100' : 'opacity-0'}`} />
                      )}
                      {isDug && !isPartOfHiddenItem && (
                        <div className="w-full h-full flex items-center justify-center">
                          <div className="w-1/3 h-1/3 bg-cyan-600/30 rounded-sm" />
                        </div>
                      )}
                    </div>
                  );
                })
              )}
            </div>

            {/* Remaining Digs Counter */}
            <div className="absolute bottom-2 right-2 bg-cyan-900/80 backdrop-blur-sm border border-cyan-400/50 rounded-lg px-3 py-2 shadow-lg">
              <div className="text-cyan-100 text-sm">
                <span className="opacity-70">本日の発掘:</span>
                <span className="ml-2 text-lg font-mono">{dailyDigs + bonusDigsRemaining}回</span>
                {bonusDigsRemaining > 0 && (
                  <span className="ml-1 text-xs text-amber-300">(+{bonusDigsRemaining})</span>
                )}
              </div>
            </div>

            {/* Click Effects */}
            {clickEffects.map(effect => (
              <div key={effect.id} className="absolute pointer-events-none" style={{ left: 0, top: 0 }}>
                {/* Ripple waves */}
                {[...Array(3)].map((_, i) => (
                  <motion.div
                    key={`ripple-${i}`}
                    className="absolute"
                    initial={{ 
                      x: effect.x - 8, 
                      y: effect.y - 8,
                      scale: 0,
                      opacity: 0.8,
                    }}
                    animate={{ 
                      scale: [0, 2.5 + i * 0.5],
                      opacity: [0.8, 0],
                    }}
                    transition={{ 
                      duration: 0.6,
                      delay: i * 0.1,
                      ease: 'easeOut'
                    }}
                  >
                    <div className="w-4 h-4 border-2 border-cyan-300 rounded-full" />
                  </motion.div>
                ))}

                {/* Sparkle particles */}
                {[...Array(8)].map((_, i) => {
                  const angle = (i * 45) + (Math.random() * 20 - 10);
                  const distance = 20 + Math.random() * 30;
                  const size = 3 + Math.random() * 4;
                  
                  return (
                    <motion.div
                      key={`particle-${i}`}
                      className="absolute"
                      initial={{ 
                        x: effect.x, 
                        y: effect.y,
                        scale: 0,
                        opacity: 1,
                      }}
                      animate={{ 
                        x: effect.x + Math.cos(angle * Math.PI / 180) * distance,
                        y: effect.y + Math.sin(angle * Math.PI / 180) * distance,
                        scale: [0, 1, 0.5],
                        opacity: [1, 1, 0],
                      }}
                      transition={{ 
                        duration: 0.6,
                        delay: i * 0.03,
                        ease: 'easeOut'
                      }}
                      style={{
                        width: `${size}px`,
                        height: `${size}px`,
                      }}
                    >
                      <Sparkles className="w-full h-full text-cyan-300" />
                    </motion.div>
                  );
                })}

                {/* Magic sparkles */}
                {[...Array(6)].map((_, i) => {
                  const angle = (i * 60) + (Math.random() * 30 - 15);
                  const distance = 15 + Math.random() * 20;
                  const colors = ['text-cyan-300', 'text-blue-400', 'text-purple-400', 'text-pink-400'];
                  const color = colors[i % colors.length];
                  
                  return (
                    <motion.div
                      key={`sparkle-${i}`}
                      className="absolute"
                      initial={{ 
                        x: effect.x - 3, 
                        y: effect.y - 3,
                        scale: 0,
                        opacity: 0,
                        rotate: 0,
                      }}
                      animate={{ 
                        x: effect.x - 3 + Math.cos(angle * Math.PI / 180) * distance,
                        y: effect.y - 3 + Math.sin(angle * Math.PI / 180) * distance,
                        scale: [0, 1.5, 0],
                        opacity: [0, 1, 0],
                        rotate: [0, 180, 360],
                      }}
                      transition={{ 
                        duration: 0.8,
                        delay: i * 0.05,
                        ease: 'easeOut'
                      }}
                    >
                      <div className="w-2 h-2 relative">
                        <div className={`absolute inset-0 ${color} blur-sm`}
                          style={{
                            background: `radial-gradient(circle, currentColor 0%, transparent 70%)`,
                          }}
                        />
                        <div className={`absolute inset-0 ${color}`}
                          style={{
                            clipPath: 'polygon(50% 0%, 61% 35%, 98% 35%, 68% 57%, 79% 91%, 50% 70%, 21% 91%, 32% 57%, 2% 35%, 39% 35%)',
                          }}
                        />
                      </div>
                    </motion.div>
                  );
                })}

                {/* Center burst */}
                <motion.div
                  className="absolute"
                  initial={{ 
                    x: effect.x - 6, 
                    y: effect.y - 6,
                    scale: 0,
                    opacity: 1,
                  }}
                  animate={{ 
                    scale: [0, 1.5, 0],
                    opacity: [1, 0.8, 0],
                  }}
                  transition={{ 
                    duration: 0.4,
                    ease: 'easeOut'
                  }}
                >
                  <div className="w-3 h-3 rounded-full bg-gradient-to-r from-cyan-400 via-blue-300 to-purple-400 shadow-[0_0_12px_rgba(34,211,238,0.8)]" />
                </motion.div>

                {/* Glow effect */}
                <motion.div
                  className="absolute"
                  initial={{ 
                    x: effect.x - 12, 
                    y: effect.y - 12,
                    scale: 0,
                    opacity: 0.6,
                  }}
                  animate={{ 
                    scale: [0, 2, 3],
                    opacity: [0.6, 0.3, 0],
                  }}
                  transition={{ 
                    duration: 0.6,
                    ease: 'easeOut'
                  }}
                >
                  <div className="w-6 h-6 rounded-full bg-cyan-400 blur-md" />
                </motion.div>
              </div>
            ))}

            {/* Ice Break Effect */}
            <AnimatePresence>
              {showIceBreak && (
                <motion.div 
                  className="absolute inset-0 pointer-events-none"
                  initial={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.3 }}
                >
                  {/* Ice cracks */}
                  {[...Array(8)].map((_, i) => {
                    const angle = (i * 45) + (Math.random() * 20 - 10);
                    const length = 40 + Math.random() * 20;
                    
                    return (
                      <motion.div
                        key={`crack-${i}`}
                        className="absolute top-1/2 left-1/2 origin-left"
                        style={{
                          transform: `rotate(${angle}deg)`,
                          width: `${length}%`,
                          height: '2px',
                        }}
                        initial={{ scaleX: 0, opacity: 0 }}
                        animate={{ scaleX: 1, opacity: 1 }}
                        transition={{ duration: 0.3, ease: 'easeOut' }}
                      >
                        <div className="h-full bg-gradient-to-r from-white via-cyan-200 to-transparent shadow-[0_0_8px_rgba(255,255,255,0.8)]" />
                      </motion.div>
                    );
                  })}
                  
                  {/* Ice shards */}
                  {[...Array(12)].map((_, i) => {
                    const angle = (i * 30) + (Math.random() * 20 - 10);
                    const distance = 150 + Math.random() * 100;
                    const rotation = Math.random() * 360;
                    const size = 20 + Math.random() * 30;
                    const delay = 0.2 + (i * 0.02);
                    
                    return (
                      <motion.div
                        key={`shard-${i}`}
                        className="absolute top-1/2 left-1/2"
                        initial={{ 
                          x: 0, 
                          y: 0, 
                          opacity: 1,
                          rotate: 0,
                          scale: 1,
                        }}
                        animate={{ 
                          x: Math.cos(angle * Math.PI / 180) * distance,
                          y: Math.sin(angle * Math.PI / 180) * distance,
                          opacity: 0,
                          rotate: rotation,
                          scale: 0.5,
                        }}
                        transition={{ 
                          duration: 0.8,
                          delay,
                          ease: 'easeOut'
                        }}
                        style={{
                          width: `${size}px`,
                          height: `${size}px`,
                        }}
                      >
                        <svg viewBox="0 0 20 20" className="w-full h-full">
                          <polygon
                            points={`10,2 ${18 - i % 3},${8 + i % 4} ${15 - i % 5},18 ${5 + i % 4},${16 - i % 3} ${2 + i % 3},${7 + i % 5}`}
                            className="fill-cyan-200 stroke-white stroke-1"
                            style={{
                              filter: 'drop-shadow(0 0 4px rgba(34, 211, 238, 0.6))',
                            }}
                          />
                        </svg>
                      </motion.div>
                    );
                  })}

                  {/* Sparkles burst */}
                  {[...Array(16)].map((_, i) => {
                    const angle = i * 22.5;
                    const distance = 80 + Math.random() * 60;
                    const delay = 0.3 + (i * 0.01);
                    
                    return (
                      <motion.div
                        key={`sparkle-${i}`}
                        className="absolute top-1/2 left-1/2"
                        initial={{ 
                          x: 0, 
                          y: 0, 
                          opacity: 0,
                          scale: 0,
                        }}
                        animate={{ 
                          x: Math.cos(angle * Math.PI / 180) * distance,
                          y: Math.sin(angle * Math.PI / 180) * distance,
                          opacity: [0, 1, 0],
                          scale: [0, 1.5, 0.5],
                        }}
                        transition={{ 
                          duration: 0.8,
                          delay,
                          ease: 'easeOut'
                        }}
                      >
                        <Sparkles className="w-4 h-4 text-cyan-300" />
                      </motion.div>
                    );
                  })}

                  {/* Central flash */}
                  <motion.div
                    className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"
                    initial={{ scale: 0, opacity: 0 }}
                    animate={{ 
                      scale: [0, 2, 1.5],
                      opacity: [0, 1, 0]
                    }}
                    transition={{ 
                      duration: 0.6,
                      delay: 0.3,
                      ease: 'easeOut'
                    }}
                  >
                    <div className="w-32 h-32 rounded-full bg-gradient-to-r from-cyan-400 via-white to-blue-400 blur-xl" />
                  </motion.div>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Progress indicator */}
            {isDigging && !showIceBreak && (
              <div className="absolute inset-0 flex items-center justify-center bg-cyan-950/80 backdrop-blur-sm">
                <div className="bg-gradient-to-br from-cyan-900/90 to-blue-900/90 backdrop-blur-md rounded-2xl p-6 shadow-xl border border-cyan-400/50">
                  <div className="w-8 h-8 mx-auto mb-3 grid grid-cols-3 gap-1">
                    <div className="bg-cyan-400 animate-pulse" style={{ animationDelay: '0s' }} />
                    <div className="bg-cyan-400 animate-pulse" style={{ animationDelay: '0.1s' }} />
                    <div className="bg-cyan-400 animate-pulse" style={{ animationDelay: '0.2s' }} />
                    <div className="bg-blue-400 animate-pulse" style={{ animationDelay: '0.3s' }} />
                    <div className="bg-blue-400 animate-pulse" style={{ animationDelay: '0.4s' }} />
                    <div className="bg-blue-400 animate-pulse" style={{ animationDelay: '0.5s' }} />
                    <div className="bg-cyan-400 animate-pulse" style={{ animationDelay: '0.6s' }} />
                    <div className="bg-cyan-400 animate-pulse" style={{ animationDelay: '0.7s' }} />
                    <div className="bg-cyan-400 animate-pulse" style={{ animationDelay: '0.8s' }} />
                  </div>
                  <div className="w-64 h-3 bg-cyan-950/50 rounded-sm overflow-hidden border border-cyan-400/30">
                    <div
                      className="h-full bg-gradient-to-r from-cyan-400 to-blue-400 transition-all duration-300"
                      style={{ width: `${progress}%` }}
                    />
                  </div>
                  <p className="text-center mt-2 text-cyan-100 font-mono">{progress}%</p>
                </div>
              </div>
            )}

            {!isDigging && clicks === 0 && (
              <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                <div className="text-center text-cyan-900">
                  <div className="w-12 h-12 mx-auto mb-2 grid grid-cols-3 gap-1 opacity-50">
                    <div className="bg-cyan-900" />
                    <div className="bg-cyan-900" />
                    <div className="bg-cyan-900" />
                    <div className="bg-cyan-900" />
                    <div className="bg-cyan-900" />
                    <div className="bg-cyan-900" />
                    <div className="bg-transparent" />
                    <div className="bg-cyan-900" />
                    <div className="bg-transparent" />
                  </div>
                  <p className="opacity-75 font-mono">Click to dig!</p>
                </div>
              </div>
            )}
          </div>
        </div>
      ) : null}

      {/* Discovery Dialog (Modal) */}
      <AnimatePresence>
        {(discoveredItem || foundNothing) && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4"
            onClick={handleReset}
          >
            <motion.div
              initial={{ scale: 0.8, opacity: 0, y: 50 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.8, opacity: 0, y: 50 }}
              transition={{ type: 'spring', damping: 25, stiffness: 300 }}
              onClick={(e) => e.stopPropagation()}
              className="bg-gradient-to-br from-cyan-900/95 to-blue-900/95 backdrop-blur-md rounded-2xl p-8 shadow-2xl border-2 border-cyan-400/50 max-w-2xl w-full relative overflow-hidden"
            >
              {/* Animated background sparkles */}
              {!foundNothing && (
                <>
                  <div className="absolute top-8 right-8">
                    <Sparkles className="w-10 h-10 text-cyan-300 animate-pulse" />
                  </div>
                  <div className="absolute top-16 right-20">
                    <Sparkles className="w-6 h-6 text-blue-300 animate-pulse" style={{ animationDelay: '0.3s' }} />
                  </div>
                  <div className="absolute top-12 right-32">
                    <Sparkles className="w-5 h-5 text-cyan-400 animate-pulse" style={{ animationDelay: '0.6s' }} />
                  </div>
                  <div className="absolute bottom-12 left-8">
                    <Sparkles className="w-7 h-7 text-purple-300 animate-pulse" style={{ animationDelay: '0.4s' }} />
                  </div>
                </>
              )}

              {foundNothing ? (
                <>
                  {/* Nothing found */}
                  <div className="text-center mb-8">
                    <motion.div
                      initial={{ scale: 0 }}
                      animate={{ scale: 1, rotate: [0, -10, 10, -10, 0] }}
                      transition={{ delay: 0.2, duration: 0.6 }}
                      className="text-8xl mb-6"
                    >
                      ❄️
                    </motion.div>
                    <h2 className="text-3xl mb-4 text-cyan-100">
                      何も見つかりませんでした...
                    </h2>
                    <p className="text-cyan-300/80 text-lg">
                      この場所には何も埋まっていないようです。<br />
                      別の場所を掘ってみましょう。
                    </p>
                  </div>
                </>
              ) : (
                <>
                  {/* Found something! */}
                  <div className="text-center mb-6">
                    <motion.div
                      initial={{ scale: 0, rotate: -180 }}
                      animate={{ scale: 1, rotate: 0 }}
                      transition={{ type: 'spring', damping: 15, stiffness: 200 }}
                      className="inline-block relative mb-4"
                    >
                      <Sparkles className="w-16 h-16 text-cyan-300" />
                      <motion.div
                        animate={{ scale: [1, 1.5, 1] }}
                        transition={{ repeat: Infinity, duration: 2 }}
                        className="absolute inset-0"
                      >
                        <Sparkles className="w-16 h-16 text-cyan-400 opacity-30" />
                      </motion.div>
                    </motion.div>
                    <motion.h2
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: 0.2 }}
                      className="text-3xl mb-2 text-cyan-100"
                    >
                      🎉 {'photo' in discoveredItem ? '記憶を発掘しました！' : 'アイテムを発掘しました！'}
                    </motion.h2>
                    {!('photo' in discoveredItem) && (discoveredItem as Item).rarity && (
                      <motion.div
                        initial={{ opacity: 0, scale: 0.8 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ delay: 0.3 }}
                        className={`inline-block px-4 py-1 rounded-full bg-gradient-to-r ${rarityColors[(discoveredItem as Item).rarity]} text-white text-sm mb-4`}
                      >
                        {rarityLabels[(discoveredItem as Item).rarity]}
                      </motion.div>
                    )}
                  </div>

                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.4 }}
                    className="mb-8"
                  >
                    <div className="relative rounded-xl overflow-hidden border-4 border-cyan-400/50 shadow-2xl shadow-cyan-400/30">
                      <img
                        src={'photo' in discoveredItem ? discoveredItem.photo : (discoveredItem as Item).image}
                        alt={'photo' in discoveredItem ? '発掘した記憶' : (discoveredItem as Item).name}
                        className="w-full aspect-video object-cover"
                      />
                      <div className="absolute inset-0 bg-gradient-to-t from-cyan-900/60 via-transparent to-transparent" />
                      
                      {/* Floating info badge */}
                      <div className="absolute bottom-4 left-4 right-4 bg-black/40 backdrop-blur-md rounded-lg p-4 border border-cyan-400/30">
                        {'photo' in discoveredItem ? (
                          <>
                            <p className="text-cyan-50 mb-2 text-lg">{discoveredItem.text}</p>
                            <p className="text-cyan-300/80 text-sm">
                              封印者: {discoveredItem.author} | {discoveredItem.createdAt.toLocaleDateString('ja-JP')}
                            </p>
                          </>
                        ) : (
                          <>
                            <h3 className="text-2xl mb-2 text-cyan-50">{(discoveredItem as Item).name}</h3>
                            <p className="text-cyan-300/80 mb-2">{(discoveredItem as Item).description}</p>
                            <p className="text-cyan-400/60 text-sm">
                              発掘日: {(discoveredItem as Item).discoveredAt.toLocaleDateString('ja-JP')}
                            </p>
                          </>
                        )}
                      </div>
                    </div>
                  </motion.div>
                </>
              )}

              <motion.button
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.6 }}
                onClick={handleReset}
                className="w-full px-8 py-4 bg-gradient-to-r from-cyan-500 to-blue-500 text-white rounded-xl hover:from-cyan-400 hover:to-blue-400 transition-all shadow-lg shadow-cyan-500/50 hover:shadow-cyan-500/70 hover:scale-105"
              >
                {bonusDigsRemaining > 0 ? `次の発掘へ (残り${bonusDigsRemaining}回)` : 'さらに発掘する'}
              </motion.button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}