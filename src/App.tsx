import { useState, useEffect } from 'react';
import { MemoryPost } from './components/MemoryPost';
import { DiggingGame } from './components/DiggingGame';
import { CreateMemory } from './components/CreateMemory';
import { Collection } from './components/Collection';
import { Achievements } from './components/Achievements';
import { Profile, UserProfile } from './components/Profile';
import { ImagePlus, Home, Snowflake, Package, Trophy, User } from 'lucide-react';
import { Item, Achievement } from './types/game';

export interface Comment {
  id: string;
  author: string;
  text: string;
  createdAt: Date;
}

export interface Memory {
  id: string;
  photo: string;
  text: string;
  author: string;
  createdAt: Date;
  discovered: boolean;
  comments: Comment[];
}

export default function App() {
  const [currentView, setCurrentView] = useState<'home' | 'create' | 'dig' | 'collection' | 'achievements'>('home');
  const [memories, setMemories] = useState<Memory[]>([]);
  const [discoveredMemories, setDiscoveredMemories] = useState<Memory[]>([]);
  const [items, setItems] = useState<Item[]>([]);
  const [achievements, setAchievements] = useState<Achievement[]>([]);
  const [totalDigs, setTotalDigs] = useState(0);
  const [showProfile, setShowProfile] = useState(false);
  const [userProfile, setUserProfile] = useState<UserProfile>({
    username: 'ゲスト',
    avatar: '',
    bio: '',
  });
  const [dailyDigs, setDailyDigs] = useState(3);

  // Load and check daily digs from localStorage
  useEffect(() => {
    const today = new Date().toDateString();
    const savedDigData = localStorage.getItem('dailyDigData');
    
    if (savedDigData) {
      const { date, remaining } = JSON.parse(savedDigData);
      
      // Check if it's a new day
      if (date === today) {
        setDailyDigs(remaining);
      } else {
        // New day, reset to 3
        setDailyDigs(3);
        localStorage.setItem('dailyDigData', JSON.stringify({ date: today, remaining: 3 }));
      }
    } else {
      // First time, initialize
      localStorage.setItem('dailyDigData', JSON.stringify({ date: today, remaining: 3 }));
    }
  }, []);

  // Save daily digs whenever it changes
  useEffect(() => {
    const today = new Date().toDateString();
    localStorage.setItem('dailyDigData', JSON.stringify({ date: today, remaining: dailyDigs }));
  }, [dailyDigs]);

  useEffect(() => {
    // Load memories from localStorage
    const savedMemories = localStorage.getItem('memories');
    if (savedMemories) {
      const parsed = JSON.parse(savedMemories);
      setMemories(parsed.map((m: any) => ({ ...m, createdAt: new Date(m.createdAt) })));
    } else {
      // Initialize with some sample memories
      const sampleMemories: Memory[] = [
        {
          id: '1',
          photo: 'https://images.unsplash.com/photo-1491002052546-bf38f186af56?w=800',
          text: '凍てつく山頂で見た氷の結晶',
          author: '氷の旅人',
          createdAt: new Date('2024-01-15'),
          discovered: false,
          comments: [],
        },
        {
          id: '2',
          photo: 'https://images.unsplash.com/photo-1483921020237-2ff51e8e4b22?w=800',
          text: 'オーロラが輝く夜の記憶',
          author: '星の観測者',
          createdAt: new Date('2024-02-20'),
          discovered: false,
          comments: [],
        },
        {
          id: '3',
          photo: 'https://images.unsplash.com/photo-1418985991508-e47386d96a71?w=800',
          text: '永久凍土に眠る古代の遺跡',
          author: '遺跡探検家',
          createdAt: new Date('2024-03-10'),
          discovered: false,
          comments: [],
        },
        {
          id: '4',
          photo: 'https://images.unsplash.com/photo-1457269449834-928af64c684d?w=800',
          text: '雪原に咲く幻の氷花',
          author: '植物学者',
          createdAt: new Date('2024-04-05'),
          discovered: false,
          comments: [],
        },
        {
          id: '5',
          photo: 'https://images.unsplash.com/photo-1519904981063-b0cf448d479e?w=800',
          text: '凍った湖の奥底に見えた光',
          author: '湖の守護者',
          createdAt: new Date('2024-05-12'),
          discovered: false,
          comments: [],
        },
      ];
      setMemories(sampleMemories);
      localStorage.setItem('memories', JSON.stringify(sampleMemories));
    }

    // Load discovered memories
    const savedDiscovered = localStorage.getItem('discoveredMemories');
    if (savedDiscovered) {
      const parsed = JSON.parse(savedDiscovered);
      setDiscoveredMemories(parsed.map((m: any) => ({ ...m, createdAt: new Date(m.createdAt) })));
    }

    // Load items
    const savedItems = localStorage.getItem('items');
    if (savedItems) {
      const parsed = JSON.parse(savedItems);
      setItems(parsed.map((i: any) => ({ ...i, discoveredAt: new Date(i.discoveredAt) })));
    }

    // Load profile
    const savedProfile = localStorage.getItem('userProfile');
    if (savedProfile) {
      setUserProfile(JSON.parse(savedProfile));
    }

    // Load achievements
    const savedAchievements = localStorage.getItem('achievements');
    if (savedAchievements) {
      setAchievements(JSON.parse(savedAchievements));
    } else {
      // Initialize achievements
      const initialAchievements: Achievement[] = [
        {
          id: 'dig_10',
          title: '初心者発掘家',
          description: '10回発掘する',
          icon: '⛏️',
          requirement: 10,
          progress: 0,
          completed: false,
          type: 'dig_count',
        },
        {
          id: 'dig_50',
          title: '熟練発掘家',
          description: '50回発掘する',
          icon: '💎',
          requirement: 50,
          progress: 0,
          completed: false,
          type: 'dig_count',
        },
        {
          id: 'gem_5',
          title: '宝石コレクター',
          description: '宝石を5つ集める',
          icon: '💍',
          requirement: 5,
          progress: 0,
          completed: false,
          type: 'gem_count',
        },
        {
          id: 'barrel_3',
          title: 'ビール樽コレクター',
          description: 'ビール樽を3つ集める',
          icon: '🛢️',
          requirement: 3,
          progress: 0,
          completed: false,
          type: 'barrel_count',
        },
        {
          id: 'bottle_5',
          title: 'ビール瓶コレクター',
          description: 'ビール瓶を5つ集める',
          icon: '🍾',
          requirement: 5,
          progress: 0,
          completed: false,
          type: 'bottle_count',
        },
        {
          id: 'glass_5',
          title: 'ガラスコレクター',
          description: 'ガラスを5つ集める',
          icon: '璃',
          requirement: 5,
          progress: 0,
          completed: false,
          type: 'glass_count',
        },
        {
          id: 'memory_10',
          title: '記憶の守護者',
          description: '記憶を10個発掘する',
          icon: '📸',
          requirement: 10,
          progress: 0,
          completed: false,
          type: 'memory_count',
        },
        {
          id: 'legendary_1',
          title: '伝説の発掘家',
          description: 'レジェンダリーアイテムを入手',
          icon: '⭐',
          requirement: 1,
          progress: 0,
          completed: false,
          type: 'legendary_count',
        },
      ];
      setAchievements(initialAchievements);
      localStorage.setItem('achievements', JSON.stringify(initialAchievements));
    }

    // Load total digs
    const savedDigs = localStorage.getItem('totalDigs');
    if (savedDigs) {
      setTotalDigs(parseInt(savedDigs));
    }
  }, []);

  const handleCreateMemory = (photo: string, text: string, author: string) => {
    const newMemory: Memory = {
      id: Date.now().toString(),
      photo,
      text,
      author,
      createdAt: new Date(),
      discovered: true, // Changed to true so it appears immediately on home
      comments: [],
    };

    const updatedMemories = [...memories, newMemory];
    setMemories(updatedMemories);
    localStorage.setItem('memories', JSON.stringify(updatedMemories));
    
    // Also add to discovered memories so it shows on home
    const updatedDiscovered = [...discoveredMemories, newMemory];
    setDiscoveredMemories(updatedDiscovered);
    localStorage.setItem('discoveredMemories', JSON.stringify(updatedDiscovered));
    
    setCurrentView('home');
  };

  const handleDiscoverMemory = (memory: Memory) => {
    const updatedDiscovered = [...discoveredMemories, { ...memory, discovered: true }];
    setDiscoveredMemories(updatedDiscovered);
    localStorage.setItem('discoveredMemories', JSON.stringify(updatedDiscovered));
  };

  const handleDiscoverItem = (item: Item) => {
    const updatedItems = [...items, item];
    setItems(updatedItems);
    localStorage.setItem('items', JSON.stringify(updatedItems));

    // Update total digs
    const newTotal = totalDigs + 1;
    setTotalDigs(newTotal);
    localStorage.setItem('totalDigs', newTotal.toString());

    // Update achievements
    updateAchievements(updatedItems, newTotal);
  };

  const updateAchievements = (currentItems: Item[], digs: number) => {
    const gemCount = currentItems.filter(i => i.type === 'gem').length;
    const barrelCount = currentItems.filter(i => i.type === 'barrel').length;
    const bottleCount = currentItems.filter(i => i.type === 'bottle').length;
    const glassCount = currentItems.filter(i => i.type === 'glass').length;
    const memoryCount = currentItems.filter(i => i.type === 'memory').length;
    const legendaryCount = currentItems.filter(i => i.rarity === 'legendary').length;

    const updatedAchievements = achievements.map(ach => {
      let newProgress = ach.progress;
      
      switch (ach.type) {
        case 'dig_count':
          newProgress = digs;
          break;
        case 'gem_count':
          newProgress = gemCount;
          break;
        case 'barrel_count':
          newProgress = barrelCount;
          break;
        case 'bottle_count':
          newProgress = bottleCount;
          break;
        case 'glass_count':
          newProgress = glassCount;
          break;
        case 'memory_count':
          newProgress = memoryCount;
          break;
        case 'legendary_count':
          newProgress = legendaryCount;
          break;
      }

      return {
        ...ach,
        progress: newProgress,
        completed: newProgress >= ach.requirement,
      };
    });

    setAchievements(updatedAchievements);
    localStorage.setItem('achievements', JSON.stringify(updatedAchievements));
  };

  const handleAddComment = (memoryId: string, commentText: string, commentAuthor: string) => {
    const newComment: Comment = {
      id: Date.now().toString(),
      author: commentAuthor,
      text: commentText,
      createdAt: new Date(),
    };

    // Update discovered memories
    const updatedDiscovered = discoveredMemories.map(m => 
      m.id === memoryId 
        ? { ...m, comments: [...m.comments, newComment] }
        : m
    );
    setDiscoveredMemories(updatedDiscovered);
    localStorage.setItem('discoveredMemories', JSON.stringify(updatedDiscovered));
  };

  const handleSaveProfile = (profile: UserProfile) => {
    setUserProfile(profile);
    localStorage.setItem('userProfile', JSON.stringify(profile));
  };

  const undiscoveredMemories = memories.filter(
    m => !discoveredMemories.some(d => d.id === m.id)
  );

  return (
    <div className="min-h-screen bg-gradient-to-br from-cyan-950 via-blue-950 to-indigo-950 relative overflow-hidden">
      {/* Animated background particles */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-20 left-10 w-2 h-2 bg-cyan-300 rounded-full animate-pulse opacity-60" />
        <div className="absolute top-40 right-20 w-3 h-3 bg-blue-300 rounded-full animate-pulse opacity-40" style={{ animationDelay: '1s' }} />
        <div className="absolute bottom-32 left-1/4 w-2 h-2 bg-cyan-400 rounded-full animate-pulse opacity-50" style={{ animationDelay: '2s' }} />
        <div className="absolute top-60 right-1/3 w-2 h-2 bg-indigo-300 rounded-full animate-pulse opacity-60" style={{ animationDelay: '0.5s' }} />
        <div className="absolute bottom-20 right-1/4 w-3 h-3 bg-cyan-200 rounded-full animate-pulse opacity-40" style={{ animationDelay: '1.5s' }} />
      </div>

      <div className="max-w-4xl mx-auto p-4 sm:p-6 relative z-10">
        {/* Header */}
        <header className="text-center mb-8 pt-6 relative">
          {/* Profile button in top right */}
          <button
            onClick={() => setShowProfile(true)}
            className="absolute top-0 right-0 p-3 bg-gradient-to-r from-cyan-500/20 to-blue-500/20 backdrop-blur-sm rounded-full border border-cyan-400/30 hover:from-cyan-500/30 hover:to-blue-500/30 transition-all"
          >
            {userProfile.avatar ? (
              <img
                src={userProfile.avatar}
                alt={userProfile.username}
                className="w-10 h-10 rounded-full object-cover border-2 border-cyan-400/50"
              />
            ) : (
              <User className="w-10 h-10 text-cyan-300" />
            )}
          </button>

          <div className="inline-block relative">
            <h1 className="text-4xl mb-2 text-transparent bg-clip-text bg-gradient-to-r from-cyan-300 via-blue-300 to-indigo-300">
              ❄️ 永久凍土の記憶
            </h1>
            <div className="absolute -top-2 -right-2 w-4 h-4 bg-cyan-400 rounded-full animate-ping opacity-50" />
          </div>
          <p className="text-cyan-200">凍てつく大地に封印された思い出を発掘せよ</p>
        </header>

        {/* Navigation */}
        <nav className="flex gap-3 mb-8 overflow-x-auto pb-2 scrollbar-thin scrollbar-thumb-cyan-500/50 scrollbar-track-transparent">
          <button
            onClick={() => setCurrentView('home')}
            className={`flex items-center gap-2 px-6 py-3 rounded-full transition-all backdrop-blur-sm flex-shrink-0 ${
              currentView === 'home'
                ? 'bg-gradient-to-r from-cyan-500 to-blue-500 text-white shadow-lg shadow-cyan-500/50'
                : 'bg-white/10 text-cyan-100 hover:bg-white/20 border border-cyan-400/30'
            }`}
          >
            <Home className="w-5 h-5" />
            ホーム
          </button>
          <button
            onClick={() => setCurrentView('create')}
            className={`flex items-center gap-2 px-6 py-3 rounded-full transition-all backdrop-blur-sm flex-shrink-0 ${
              currentView === 'create'
                ? 'bg-gradient-to-r from-cyan-500 to-blue-500 text-white shadow-lg shadow-cyan-500/50'
                : 'bg-white/10 text-cyan-100 hover:bg-white/20 border border-cyan-400/30'
            }`}
          >
            <ImagePlus className="w-5 h-5" />
            封印
          </button>
          <button
            onClick={() => setCurrentView('dig')}
            className={`flex items-center gap-2 px-6 py-3 rounded-full transition-all backdrop-blur-sm flex-shrink-0 ${
              currentView === 'dig'
                ? 'bg-gradient-to-r from-cyan-500 to-blue-500 text-white shadow-lg shadow-cyan-500/50'
                : 'bg-white/10 text-cyan-100 hover:bg-white/20 border border-cyan-400/30'
            }`}
          >
            <Snowflake className="w-5 h-5" />
            発掘
          </button>
          <button
            onClick={() => setCurrentView('collection')}
            className={`flex items-center gap-2 px-6 py-3 rounded-full transition-all backdrop-blur-sm flex-shrink-0 ${
              currentView === 'collection'
                ? 'bg-gradient-to-r from-cyan-500 to-blue-500 text-white shadow-lg shadow-cyan-500/50'
                : 'bg-white/10 text-cyan-100 hover:bg-white/20 border border-cyan-400/30'
            }`}
          >
            <Package className="w-5 h-5" />
            コレクション
          </button>
          <button
            onClick={() => setCurrentView('achievements')}
            className={`flex items-center gap-2 px-6 py-3 rounded-full transition-all backdrop-blur-sm flex-shrink-0 ${
              currentView === 'achievements'
                ? 'bg-gradient-to-r from-cyan-500 to-blue-500 text-white shadow-lg shadow-cyan-500/50'
                : 'bg-white/10 text-cyan-100 hover:bg-white/20 border border-cyan-400/30'
            }`}
          >
            <Trophy className="w-5 h-5" />
            実績
          </button>
        </nav>

        {/* Main Content */}
        <main>
          {currentView === 'home' && (
            <div>
              <h2 className="text-2xl mb-4 text-cyan-100">発掘した記憶</h2>
              {discoveredMemories.length === 0 ? (
                <div className="bg-white/5 backdrop-blur-md rounded-2xl p-12 text-center shadow-xl border border-cyan-400/20">
                  <Snowflake className="w-16 h-16 mx-auto mb-4 text-cyan-300 animate-spin" style={{ animationDuration: '10s' }} />
                  <p className="text-cyan-200 mb-2">まだ記憶を発掘していません</p>
                  <p className="text-cyan-300/60">「発掘」から凍土を掘り起こしましょう</p>
                </div>
              ) : (
                <div className="grid gap-4 sm:grid-cols-2">
                  {discoveredMemories.map((memory) => (
                    <MemoryPost key={memory.id} memory={memory} onAddComment={handleAddComment} />
                  ))}
                </div>
              )}
            </div>
          )}

          {currentView === 'create' && (
            <CreateMemory onSubmit={handleCreateMemory} onCancel={() => setCurrentView('home')} />
          )}

          {currentView === 'dig' && (
            <DiggingGame
              undiscoveredMemories={undiscoveredMemories}
              onDiscover={handleDiscoverMemory}
              onDiscoverItem={handleDiscoverItem}
              dailyDigs={dailyDigs}
              setDailyDigs={setDailyDigs}
            />
          )}

          {currentView === 'collection' && (
            <Collection items={items} />
          )}

          {currentView === 'achievements' && (
            <Achievements achievements={achievements} totalDigs={totalDigs} />
          )}
        </main>

        {/* Profile Modal */}
        {showProfile && (
          <Profile
            profile={userProfile}
            onSave={handleSaveProfile}
            onClose={() => setShowProfile(false)}
          />
        )}
      </div>
    </div>
  );
}