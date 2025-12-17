import '../models/memory.dart';
import '../models/comment.dart';

class DemoData {
  static List<Memory> getMemories() {
    return [
      Memory(
        id: 'demo_1',
        photo: 'https://images.unsplash.com/photo-1502082553048-f009c37129b9?q=80&w=600&h=400&fit=crop', // 静かな森
        text: '朝の5時、誰もいない森で深呼吸。空気の冷たさが肺に染みた。',
        author: 'ノマドの旅人',
        authorId: 'demo_user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        discovered: false,
        starRating: 3,
        comments: List.generate(8, (_) => Comment(id: '', author: '', text: '', createdAt: DateTime.now())),
      ),
      Memory(
        id: 'demo_2',
        photo: 'https://images.unsplash.com/photo-1518005020250-6e594d673e4b?q=80&w=600&h=400&fit=crop', // 都会の夜景
        text: 'ビル群の光がまるで回路のよう。ここには数えきれないほどの物語がある。',
        author: '都市の観測者',
        authorId: 'demo_user_2',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        discovered: false,
        starRating: 2,
        comments: List.generate(15, (_) => Comment(id: '', author: '', text: '', createdAt: DateTime.now())),
      ),
      Memory(
        id: 'demo_3',
        photo: 'https://images.unsplash.com/photo-1471922694854-ff1b63b20054?q=80&w=600&h=400&fit=crop', // 海辺の夕日
        text: '波の音を聞きながら、何時間も水平線を眺めていた。自分はただの砂粒の一つ。',
        author: '水平線を見つめる者',
        authorId: 'demo_user_3',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        discovered: false,
        starRating: 3,
        comments: List.generate(4, (_) => Comment(id: '', author: '', text: '', createdAt: DateTime.now())),
      ),
      Memory(
        id: 'demo_4',
        photo: 'https://images.unsplash.com/photo-1520113282655-142d517c1340?q=80&w=600&h=400&fit=crop', // 古い喫茶店
        text: '使い古されたカップの底に、かつて誰かが語った秘密が残っている気がした。',
        author: '珈琲中毒',
        authorId: 'demo_user_4',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        discovered: true, // 既に発見されているデモ
        starRating: 3,
        comments: List.generate(22, (_) => Comment(id: '', author: '', text: '', createdAt: DateTime.now())),
      ),
      Memory(
        id: 'demo_5',
        photo: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=600&h=400&fit=crop', // 壮大な山脈
        text: '頂上に立った瞬間、全てがちっぽけに見えた。この風を忘れたくない。',
        author: '登山家',
        authorId: 'demo_user_5',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        discovered: false,
        starRating: 3,
        comments: List.generate(10, (_) => Comment(id: '', author: '', text: '', createdAt: DateTime.now())),
      ),
    ];
  }
}