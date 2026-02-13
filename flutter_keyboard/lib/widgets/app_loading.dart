import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class AppLoading extends StatelessWidget {
  final String? message;

  const AppLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppLoadingScreen extends StatefulWidget {
  final String? message;

  const AppLoadingScreen({super.key, this.message});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Dim version (background)
                      Opacity(
                        opacity: 0.15,
                        child: child!,
                      ),
                      // Filled version clipped from bottom to top
                      ClipRect(
                        clipper: _FillClipper(_controller.value),
                        child: child,
                      ),
                    ],
                  );
                },
                child: Image.asset(
                  'assets/images/load_icon.png',
                  width: 100,
                  height: 100,
                  semanticLabel: 'Desenrola AI',
                ),
              ),
            ),
            if (widget.message != null) ...[
              const SizedBox(height: 24),
              Text(
                widget.message!,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Clips from bottom to top based on progress (0.0 = empty, 1.0 = full)
class _FillClipper extends CustomClipper<Rect> {
  final double progress;

  _FillClipper(this.progress);

  @override
  Rect getClip(Size size) {
    // Fill from bottom to top
    final top = size.height * (1.0 - progress);
    return Rect.fromLTRB(0, top, size.width, size.height);
  }

  @override
  bool shouldReclip(_FillClipper oldClipper) => oldClipper.progress != progress;
}
