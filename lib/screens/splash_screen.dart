import 'package:flutter/material.dart';

/// Simple splash screen with a fade-in animation.
/// Duration chosen as 2 seconds to match `docs/ux-spec.md`.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward().whenComplete(() {
      // After animation completes, navigate to auth screen.
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _opacity,
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              FlutterLogo(size: 120),
              SizedBox(height: 16),
              Text(
                'PlantCare.ID',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
