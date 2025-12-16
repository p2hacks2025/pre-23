export type ItemType = 'memory' | 'gem' | 'barrel' | 'bottle' | 'glass';
export type Rarity = 'common' | 'rare' | 'epic' | 'legendary';

export interface Item {
  id: string;
  type: ItemType;
  name: string;
  description: string;
  rarity: Rarity;
  image: string;
  discoveredAt: Date;
  memoryId?: string; // For memory items
}

export interface Achievement {
  id: string;
  title: string;
  description: string;
  icon: string;
  requirement: number;
  progress: number;
  completed: boolean;
  type: 'dig_count' | 'gem_count' | 'barrel_count' | 'bottle_count' | 'glass_count' | 'memory_count' | 'legendary_count' | 'collection_complete';
}