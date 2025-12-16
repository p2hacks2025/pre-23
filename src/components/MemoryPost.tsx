import { Memory } from '../App';
import { Calendar, User, Sparkles, MessageCircle, Send } from 'lucide-react';
import { useState } from 'react';

interface MemoryPostProps {
  memory: Memory;
  onAddComment: (memoryId: string, text: string, author: string) => void;
}

export function MemoryPost({ memory, onAddComment }: MemoryPostProps) {
  const [showComments, setShowComments] = useState(false);
  const [commentText, setCommentText] = useState('');
  const [commentAuthor, setCommentAuthor] = useState('');

  // Ensure comments array exists
  const comments = memory.comments || [];

  const handleSubmitComment = (e: React.FormEvent) => {
    e.preventDefault();
    if (commentText.trim() && commentAuthor.trim()) {
      onAddComment(memory.id, commentText, commentAuthor);
      setCommentText('');
      setCommentAuthor('');
    }
  };

  return (
    <div className="bg-gradient-to-br from-cyan-900/40 to-blue-900/40 backdrop-blur-md rounded-2xl overflow-hidden shadow-xl border border-cyan-400/30 hover:border-cyan-400/60 transition-all hover:shadow-cyan-400/20 relative group">
      {/* Sparkle effect on hover */}
      <div className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity z-10">
        <Sparkles className="w-5 h-5 text-cyan-300 animate-pulse" />
      </div>
      
      <div className="aspect-video w-full overflow-hidden bg-gradient-to-br from-cyan-950 to-blue-950 relative">
        <img
          src={memory.photo}
          alt="思い出の写真"
          className="w-full h-full object-cover opacity-90"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-cyan-900/50 to-transparent" />
      </div>
      <div className="p-4">
        <p className="mb-3 text-cyan-50">{memory.text}</p>
        <div className="flex items-center gap-4 text-cyan-300/80 mb-3">
          <div className="flex items-center gap-1">
            <User className="w-4 h-4" />
            <span className="text-sm">{memory.author}</span>
          </div>
          <div className="flex items-center gap-1">
            <Calendar className="w-4 h-4" />
            <span className="text-sm">
              {memory.createdAt.toLocaleDateString('ja-JP')}
            </span>
          </div>
        </div>

        {/* Comment Toggle Button */}
        <button
          onClick={() => setShowComments(!showComments)}
          className="flex items-center gap-2 text-cyan-300 hover:text-cyan-200 transition-colors mb-3"
        >
          <MessageCircle className="w-4 h-4" />
          <span className="text-sm">
            コメント ({comments.length})
          </span>
        </button>

        {/* Comments Section */}
        {showComments && (
          <div className="mt-3 pt-3 border-t border-cyan-400/20">
            {/* Comment List */}
            {comments.length > 0 && (
              <div className="mb-3 space-y-2 max-h-48 overflow-y-auto">
                {comments.map((comment) => (
                  <div key={comment.id} className="bg-cyan-950/30 rounded-lg p-2 backdrop-blur-sm border border-cyan-400/10">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-cyan-200 text-sm">{comment.author}</span>
                      <span className="text-cyan-400/60 text-xs">
                        {comment.createdAt.toLocaleDateString('ja-JP')}
                      </span>
                    </div>
                    <p className="text-cyan-100 text-sm">{comment.text}</p>
                  </div>
                ))}
              </div>
            )}

            {/* Comment Form */}
            <form onSubmit={handleSubmitComment} className="space-y-2">
              <input
                type="text"
                value={commentAuthor}
                onChange={(e) => setCommentAuthor(e.target.value)}
                placeholder="名前"
                className="w-full px-3 py-2 bg-cyan-950/50 backdrop-blur-sm border border-cyan-400/30 rounded-lg text-cyan-50 placeholder-cyan-400/50 text-sm focus:outline-none focus:ring-1 focus:ring-cyan-400"
                required
              />
              <div className="flex gap-2">
                <input
                  type="text"
                  value={commentText}
                  onChange={(e) => setCommentText(e.target.value)}
                  placeholder="コメントを書く..."
                  className="flex-1 px-3 py-2 bg-cyan-950/50 backdrop-blur-sm border border-cyan-400/30 rounded-lg text-cyan-50 placeholder-cyan-400/50 text-sm focus:outline-none focus:ring-1 focus:ring-cyan-400"
                  required
                />
                <button
                  type="submit"
                  className="px-4 py-2 bg-gradient-to-r from-cyan-500 to-blue-500 text-white rounded-lg hover:from-cyan-400 hover:to-blue-400 transition-all shadow-md shadow-cyan-500/20"
                >
                  <Send className="w-4 h-4" />
                </button>
              </div>
            </form>
          </div>
        )}
      </div>
    </div>
  );
}
