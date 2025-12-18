import '../models/memory.dart';

class DemoData {
  static List<Memory> getMemories() {
    return [
      Memory(
        id: 'demo_1',
        photo: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800', // 森
        text: '朝の5時、誰もいない森で深呼吸。空気の冷たさが肺に染みた。',
        author: 'ノマドの旅人',
        authorId: 'demo_user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        discovered: false,
        starRating: 3,
        comments: [],
        guestComments: [], // ★ 追加
        stampsCount: 0,
        digCount: 2, // 2回誰かに叩かれた形跡
      ),
      Memory(
        id: 'demo_2',
        photo: 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=800', // 都会
        text: 'ビル群の光がまるで回路のよう。ここには数えきれないほどの物語がある。',
        author: '都市の観測者',
        authorId: 'demo_user_2',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        discovered: false,
        starRating: 2,
        comments: [],
        guestComments: [], // ★ 追加
        stampsCount: 5, // 5個のキラキラが付いている
        digCount: 12,
      ),
      Memory(
        id: 'demo_3',
        photo: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800', // 海
        text: '波の音を聞きながら、何時間も水平線を眺めていた。自分はただの砂粒の一つ。',
        author: '水平線を見つめる者',
        authorId: 'demo_user_3',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        discovered: false,
        starRating: 3,
        comments: [],
        guestComments: [], // ★ 追加
        stampsCount: 0,
        digCount: 0,
      ),
      Memory(
        id: 'demo_4',
        photo: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800', // カフェ
        text: '使い古されたカップの底に、かつて誰かが語った秘密が残っている気がした。',
        author: '珈琲中毒',
        authorId: 'demo_user_4',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        discovered: true, // ★ 発掘済み
        starRating: 3,
        comments: [],
        guestComments: ['落ち着く...', '素敵な秘密'], // ★ 10文字コメントのデモ
        stampsCount: 12,
        digCount: 25,
      ),
    ];
  }
}