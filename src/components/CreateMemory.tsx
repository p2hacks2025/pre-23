import { useState } from 'react';
import { Upload, X, Sparkles } from 'lucide-react';

interface CreateMemoryProps {
  onSubmit: (photo: string, text: string, author: string) => void;
  onCancel: () => void;
}

export function CreateMemory({ onSubmit, onCancel }: CreateMemoryProps) {
  const [photo, setPhoto] = useState<string>('');
  const [text, setText] = useState('');
  const [author, setAuthor] = useState('');

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setPhoto(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (photo && text && author) {
      onSubmit(photo, text, author);
      // Reset form after submission
      setPhoto('');
      setText('');
      setAuthor('');
    }
  };

  return (
    <div className="bg-gradient-to-br from-cyan-900/40 to-blue-900/40 backdrop-blur-md rounded-2xl p-6 shadow-xl border border-cyan-400/30 max-w-2xl mx-auto relative">
      {/* Decorative sparkles */}
      <div className="absolute top-4 right-4">
        <Sparkles className="w-6 h-6 text-cyan-300 animate-pulse" />
      </div>
      
      <h2 className="text-2xl mb-6 text-cyan-100">記憶を永久凍土に封印</h2>
      
      <form onSubmit={handleSubmit}>
        {/* Photo Upload */}
        <div className="mb-6">
          <label className="block mb-2 text-cyan-200">写真</label>
          {!photo ? (
            <label className="flex flex-col items-center justify-center w-full h-64 border-2 border-dashed border-cyan-400/50 rounded-xl cursor-pointer hover:bg-cyan-800/20 transition-colors backdrop-blur-sm">
              <Upload className="w-12 h-12 text-cyan-300 mb-2" />
              <span className="text-cyan-200">クリックして写真を選択</span>
              <input
                type="file"
                accept="image/*"
                onChange={handlePhotoUpload}
                className="hidden"
                required
              />
            </label>
          ) : (
            <div className="relative">
              <img
                src={photo}
                alt="アップロード写真"
                className="w-full h-64 object-cover rounded-xl border border-cyan-400/30"
              />
              <button
                type="button"
                onClick={() => setPhoto('')}
                className="absolute top-2 right-2 p-2 bg-cyan-900/80 backdrop-blur-sm rounded-full shadow-lg hover:bg-cyan-800 border border-cyan-400/30"
              >
                <X className="w-5 h-5 text-cyan-100" />
              </button>
            </div>
          )}
        </div>

        {/* Comment Input */}
        <div className="mb-6">
          <label className="block mb-2 text-cyan-200">コメント</label>
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="この写真についてのコメントを書いてください..."
            className="w-full px-4 py-3 bg-cyan-950/50 backdrop-blur-sm border border-cyan-400/30 rounded-xl focus:outline-none focus:ring-2 focus:ring-cyan-400 resize-none text-cyan-50 placeholder-cyan-400/50"
            rows={4}
            required
          />
        </div>

        {/* Author Name Input */}
        <div className="mb-6">
          <label className="block mb-2 text-cyan-200">投稿者名</label>
          <input
            type="text"
            value={author}
            onChange={(e) => setAuthor(e.target.value)}
            placeholder="あなたの名前を入力してください"
            className="w-full px-4 py-3 bg-cyan-950/50 backdrop-blur-sm border border-cyan-400/30 rounded-xl focus:outline-none focus:ring-2 focus:ring-cyan-400 text-cyan-50 placeholder-cyan-400/50"
            required
          />
        </div>

        {/* Submit Buttons */}
        <div className="flex gap-3">
          <button
            type="button"
            onClick={onCancel}
            className="flex-1 px-6 py-3 bg-cyan-950/50 backdrop-blur-sm text-cyan-100 border border-cyan-400/30 rounded-xl hover:bg-cyan-900/50 transition-colors"
          >
            キャンセル
          </button>
          <button
            type="submit"
            className="flex-1 px-6 py-3 bg-gradient-to-r from-cyan-500 to-blue-500 text-white rounded-xl hover:from-cyan-400 hover:to-blue-400 transition-all shadow-lg shadow-cyan-500/30"
          >
            封印する
          </button>
        </div>
      </form>
    </div>
  );
}
