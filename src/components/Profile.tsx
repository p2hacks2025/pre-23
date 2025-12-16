import { useState } from 'react';
import { Upload, X, User, Sparkles } from 'lucide-react';

export interface UserProfile {
  username: string;
  avatar: string;
  bio: string;
}

interface ProfileProps {
  profile: UserProfile;
  onSave: (profile: UserProfile) => void;
  onClose: () => void;
}

export function Profile({ profile, onSave, onClose }: ProfileProps) {
  const [username, setUsername] = useState(profile.username);
  const [avatar, setAvatar] = useState(profile.avatar);
  const [bio, setBio] = useState(profile.bio);

  const handleAvatarUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setAvatar(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (username) {
      onSave({ username, avatar, bio });
      onClose();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
      <div className="bg-gradient-to-br from-cyan-900/95 to-blue-900/95 backdrop-blur-md rounded-2xl p-6 shadow-xl border border-cyan-400/30 max-w-lg w-full relative">
        {/* Close button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 p-2 bg-cyan-950/50 rounded-full hover:bg-cyan-900/50 transition-colors border border-cyan-400/30"
        >
          <X className="w-5 h-5 text-cyan-100" />
        </button>

        {/* Decorative sparkles */}
        <div className="absolute top-4 left-4">
          <Sparkles className="w-6 h-6 text-cyan-300 animate-pulse" />
        </div>

        <h2 className="text-2xl mb-6 text-cyan-100 text-center">プロフィール設定</h2>

        <form onSubmit={handleSubmit}>
          {/* Avatar Upload */}
          <div className="mb-6">
            <label className="block mb-2 text-cyan-200 text-center">プロフィール画像</label>
            <div className="flex justify-center mb-4">
              {avatar ? (
                <div className="relative">
                  <img
                    src={avatar}
                    alt="プロフィール画像"
                    className="w-32 h-32 rounded-full object-cover border-4 border-cyan-400/50 shadow-lg shadow-cyan-400/20"
                  />
                  <button
                    type="button"
                    onClick={() => setAvatar('')}
                    className="absolute -top-2 -right-2 p-1.5 bg-cyan-900/80 backdrop-blur-sm rounded-full shadow-lg hover:bg-cyan-800 border border-cyan-400/30"
                  >
                    <X className="w-4 h-4 text-cyan-100" />
                  </button>
                </div>
              ) : (
                <label className="w-32 h-32 rounded-full border-2 border-dashed border-cyan-400/50 flex flex-col items-center justify-center cursor-pointer hover:bg-cyan-800/20 transition-colors backdrop-blur-sm">
                  <User className="w-12 h-12 text-cyan-300 mb-1" />
                  <span className="text-cyan-200 text-xs">画像を選択</span>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleAvatarUpload}
                    className="hidden"
                  />
                </label>
              )}
            </div>
          </div>

          {/* Username Input */}
          <div className="mb-6">
            <label className="block mb-2 text-cyan-200">ユーザー名 *</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="あなたの名前を入力"
              className="w-full px-4 py-3 bg-cyan-950/50 backdrop-blur-sm border border-cyan-400/30 rounded-xl focus:outline-none focus:ring-2 focus:ring-cyan-400 text-cyan-50 placeholder-cyan-400/50"
              required
            />
          </div>

          {/* Bio Input */}
          <div className="mb-6">
            <label className="block mb-2 text-cyan-200">自己紹介</label>
            <textarea
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              placeholder="あなたについて教えてください..."
              className="w-full px-4 py-3 bg-cyan-950/50 backdrop-blur-sm border border-cyan-400/30 rounded-xl focus:outline-none focus:ring-2 focus:ring-cyan-400 resize-none text-cyan-50 placeholder-cyan-400/50"
              rows={3}
            />
          </div>

          {/* Buttons */}
          <div className="flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-6 py-3 bg-cyan-950/50 backdrop-blur-sm text-cyan-100 border border-cyan-400/30 rounded-xl hover:bg-cyan-900/50 transition-colors"
            >
              キャンセル
            </button>
            <button
              type="submit"
              className="flex-1 px-6 py-3 bg-gradient-to-r from-cyan-500 to-blue-500 text-white rounded-xl hover:from-cyan-400 hover:to-blue-400 transition-all shadow-lg shadow-cyan-500/30"
            >
              保存
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
