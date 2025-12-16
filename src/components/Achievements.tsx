import { Achievement } from '../types/game';
import { Trophy, Check } from 'lucide-react';

interface AchievementsProps {
  achievements: Achievement[];
  totalDigs: number;
}

export function Achievements({ achievements, totalDigs }: AchievementsProps) {
  const completedCount = achievements.filter(a => a.completed).length;

  return (
    <div>
      <h2 className="text-2xl mb-4 text-cyan-100">実績</h2>

      {/* Stats */}
      <div className="bg-gradient-to-br from-cyan-900/40 to-blue-900/40 backdrop-blur-md rounded-2xl p-6 mb-6 shadow-xl border border-cyan-400/30">
        <div className="flex items-center justify-between">
          <div>
            <div className="text-3xl mb-1 text-cyan-100">
              {completedCount} / {achievements.length}
            </div>
            <div className="text-cyan-300/80">達成した実績</div>
          </div>
          <div className="text-right">
            <div className="text-3xl mb-1 text-cyan-100">{totalDigs}</div>
            <div className="text-cyan-300/80">総発掘回数</div>
          </div>
        </div>
      </div>

      {/* Achievements List */}
      <div className="space-y-4">
        {achievements.map((achievement) => {
          const progressPercent = Math.min((achievement.progress / achievement.requirement) * 100, 100);

          return (
            <div
              key={achievement.id}
              className={`bg-gradient-to-br from-cyan-900/40 to-blue-900/40 backdrop-blur-md rounded-2xl p-6 shadow-xl border transition-all ${
                achievement.completed
                  ? 'border-amber-400/50 shadow-amber-400/20'
                  : 'border-cyan-400/30'
              }`}
            >
              <div className="flex items-start gap-4">
                {/* Icon */}
                <div className={`text-4xl ${achievement.completed ? 'animate-pulse' : 'opacity-60'}`}>
                  {achievement.icon}
                </div>

                {/* Content */}
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-2">
                    <h3 className="text-cyan-100">{achievement.title}</h3>
                    {achievement.completed && (
                      <div className="flex items-center gap-1 px-2 py-1 bg-amber-500/20 rounded-full border border-amber-400/50">
                        <Check className="w-3 h-3 text-amber-300" />
                        <span className="text-amber-300 text-xs">達成</span>
                      </div>
                    )}
                  </div>
                  <p className="text-cyan-300/70 text-sm mb-3">{achievement.description}</p>

                  {/* Progress Bar */}
                  <div className="space-y-1">
                    <div className="flex items-center justify-between text-xs text-cyan-300/80">
                      <span>進捗</span>
                      <span>
                        {achievement.progress} / {achievement.requirement}
                      </span>
                    </div>
                    <div className="h-2 bg-cyan-950/50 rounded-full overflow-hidden border border-cyan-400/20">
                      <div
                        className={`h-full transition-all duration-500 ${
                          achievement.completed
                            ? 'bg-gradient-to-r from-amber-400 to-orange-500 shadow-lg shadow-amber-400/50'
                            : 'bg-gradient-to-r from-cyan-400 to-blue-500'
                        }`}
                        style={{ width: `${progressPercent}%` }}
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
