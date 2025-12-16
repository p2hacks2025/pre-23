import { Item } from '../types/game';
import { Sparkles } from 'lucide-react';

interface CollectionProps {
  items: Item[];
}

const rarityColors = {
  common: 'from-gray-400 to-gray-600',
  rare: 'from-blue-400 to-blue-600',
  epic: 'from-purple-400 to-purple-600',
  legendary: 'from-amber-400 to-orange-600',
};

const rarityBorders = {
  common: 'border-gray-400/50',
  rare: 'border-blue-400/50',
  epic: 'border-purple-400/50',
  legendary: 'border-amber-400/50',
};

const rarityLabels = {
  common: 'コモン',
  rare: 'レア',
  epic: 'エピック',
  legendary: 'レジェンダリー',
};

export function Collection({ items }: CollectionProps) {
  const sortedItems = [...items].sort((a, b) => 
    b.discoveredAt.getTime() - a.discoveredAt.getTime()
  );

  const stats = {
    total: items.length,
    gems: items.filter(i => i.type === 'gem').length,
    barrels: items.filter(i => i.type === 'barrel').length,
    bottles: items.filter(i => i.type === 'bottle').length,
    glasses: items.filter(i => i.type === 'glass').length,
    memories: items.filter(i => i.type === 'memory').length,
  };

  return (
    <div>
      <h2 className="text-2xl mb-4 text-cyan-100">コレクション</h2>
      
      {/* Stats */}
      <div className="bg-gradient-to-br from-cyan-900/40 to-blue-900/40 backdrop-blur-md rounded-2xl p-6 mb-6 shadow-xl border border-cyan-400/30">
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
          <div className="text-center">
            <div className="text-3xl mb-1 text-cyan-100">{stats.total}</div>
            <div className="text-cyan-300/80 text-sm">総アイテム数</div>
          </div>
          <div className="text-center">
            <div className="text-3xl mb-1">💎</div>
            <div className="text-cyan-300/80 text-sm">宝石 {stats.gems}</div>
          </div>
          <div className="text-center">
            <div className="text-3xl mb-1">🛢️</div>
            <div className="text-cyan-300/80 text-sm">樽 {stats.barrels}</div>
          </div>
          <div className="text-center">
            <div className="text-3xl mb-1">🍾</div>
            <div className="text-cyan-300/80 text-sm">瓶 {stats.bottles}</div>
          </div>
          <div className="text-center">
            <div className="text-3xl mb-1">🍺</div>
            <div className="text-cyan-300/80 text-sm">グラス {stats.glasses}</div>
          </div>
          <div className="text-center">
            <div className="text-3xl mb-1">📸</div>
            <div className="text-cyan-300/80 text-sm">記憶 {stats.memories}</div>
          </div>
        </div>
      </div>

      {/* Items Grid */}
      {items.length === 0 ? (
        <div className="bg-white/5 backdrop-blur-md rounded-2xl p-12 text-center shadow-xl border border-cyan-400/20">
          <Sparkles className="w-16 h-16 mx-auto mb-4 text-cyan-300 opacity-50" />
          <p className="text-cyan-200 mb-2">まだアイテムを発掘していません</p>
          <p className="text-cyan-300/60">発掘を始めてコレクションを増やしましょう！</p>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {sortedItems.map((item) => (
            <div
              key={item.id}
              className={`bg-gradient-to-br from-cyan-900/40 to-blue-900/40 backdrop-blur-md rounded-2xl overflow-hidden shadow-xl border-2 ${rarityBorders[item.rarity]} hover:scale-105 transition-transform relative group`}
            >
              {/* Rarity badge */}
              <div className={`absolute top-2 right-2 px-3 py-1 rounded-full text-xs text-white bg-gradient-to-r ${rarityColors[item.rarity]} shadow-lg z-10`}>
                {rarityLabels[item.rarity]}
              </div>

              {/* Sparkle effect for legendary */}
              {item.rarity === 'legendary' && (
                <div className="absolute top-2 left-2 z-10">
                  <Sparkles className="w-5 h-5 text-amber-300 animate-pulse" />
                </div>
              )}

              {/* Image */}
              <div className="aspect-square w-full overflow-hidden bg-gradient-to-br from-cyan-950 to-blue-950 relative">
                <img
                  src={item.image}
                  alt={item.name}
                  className="w-full h-full object-cover opacity-90"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-cyan-900/60 to-transparent" />
              </div>

              {/* Content */}
              <div className="p-4">
                <h3 className="text-cyan-50 mb-1">{item.name}</h3>
                <p className="text-cyan-300/70 text-sm mb-2">{item.description}</p>
                <div className="text-cyan-400/60 text-xs">
                  {item.discoveredAt.toLocaleDateString('ja-JP')}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}