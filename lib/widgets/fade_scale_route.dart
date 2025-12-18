import 'package:flutter/material.dart';

/// 画面がふわっと不透明度を変えながら拡大して表示されるカスタムルート
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeScaleRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 不透明度のアニメーション（0.0 -> 1.0）
            var opacity = animation.drive(Tween(begin: 0.0, end: 1.0));
            
            // スケールのアニメーション（0.9 -> 1.0）
            var scale = animation.drive(Tween(begin: 0.9, end: 1.0).chain(
              CurveTween(curve: Curves.easeOutCubic),
            ));

            return FadeTransition(
              opacity: opacity,
              child: ScaleTransition(
                scale: scale,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300), // アニメーション速度
        );
}