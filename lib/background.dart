import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Animation<double> animation;
  final double touchX;
  final double touchY;
  final bool isTouched;

  const AnimatedBackground({
    super.key,
    required this.animation,
    required this.touchX,
    required this.touchY,
    required this.isTouched,
  });

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<Offset> dotPositions = [];
  final List<double> dotSpeeds = [];
  final List<String> foodEmojis = [];
  final int numDots = 100;
  final math.Random random = math.Random();
  double directionX = 0;
  double directionY = 1;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < numDots; i++) {
      dotPositions
          .add(Offset(random.nextDouble() * 1000, random.nextDouble() * 1000));
      dotSpeeds.add(random.nextDouble() * 0.5 + 0.1);
      foodEmojis.add(_getRandomFoodEmoji());
    }
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    Future.delayed(const Duration(seconds: 5), _changeDirection);
  }

  void _changeDirection() {
    if (!mounted) return;
    setState(() {
      directionX = random.nextDouble() * 2 - 1;
      directionY = random.nextDouble() * 2 - 1;
    });
    if (mounted) {
      Future.delayed(const Duration(seconds: 5), _changeDirection);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getRandomFoodEmoji() {
    final foodEmojiList = [
      '🍔',
      '🌭',
      '🍕',
      '🍗',
      '🍖',
      '🍛',
      '🍜',
      '🍝',
      '🌮',
      '🌯',
      '🥙',
      '🍱',
      '🍣',
      '🍤',
      '🥩',
      '🥘',
      '🍲',
      '🍩',
      '🍪',
      '🍫',
      '🍦',
      '🍨',
      '🎂',
      '🍰',
      '🥧',
      '🍮',
      '🍡',
      '☕',
      '🍵',
      '🥤',
      '🍹',
      '🍷',
      '🍺',
      '🍼',
      '🍟',
      '🍿',
      '🥨',
      '🌰',
      '🥜'
    ];
    return foodEmojiList[random.nextInt(foodEmojiList.length)];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _BackgroundPainter(
            animation: widget.animation,
            dotPositions: dotPositions,
            dotSpeeds: dotSpeeds,
            foodEmojis: foodEmojis,
            directionX: directionX,
            directionY: directionY,
            context: context,
            touchX: widget.touchX,
            touchY: widget.touchY,
            isTouched: widget.isTouched,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Offset> dotPositions;
  final List<double> dotSpeeds;
  final List<String> foodEmojis;
  final double directionX;
  final double directionY;
  final BuildContext context;
  final double touchX;
  final double touchY;
  final bool isTouched;

  const _BackgroundPainter({
    required this.animation,
    required this.dotPositions,
    required this.dotSpeeds,
    required this.foodEmojis,
    required this.directionX,
    required this.directionY,
    required this.context,
    required this.touchX,
    required this.touchY,
    required this.isTouched,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Dynamic Gradient Background
    List<Color> gradientColors = Theme.of(context).brightness == Brightness.dark
        ? [
            const Color(0xFF1A1A1A),
            const Color(0xFF2D2D2D),
            const Color(0xFF333333),
            const Color(0xFF454545),
          ]
        : [
            const Color(0xFFFFF3E0),
            const Color(0xFFFFE0B2),
            const Color(0xFFFFD700),
            const Color(0xFFFFC400),
          ];

    final baseGradientPaint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors,
        begin: Alignment(
          animation.value * 2 - 1,
          animation.value * 2 - 1,
        ),
        end: Alignment(
          2 - animation.value * 2,
          2 - animation.value * 2,
        ),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      baseGradientPaint,
    );

    // Glowing Lines Effect
    final linePaint = Paint()
      ..color = Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.1)
      ..strokeWidth = 0.5;

    for (int i = 0; i < 20; i++) {
      final offset = (animation.value * size.width) % (size.width / 20);
      final start = Offset(
        i * (size.width / 20) - offset,
        0 + (i * 5).toDouble(),
      );
      final end = Offset(
        i * (size.width / 20) - offset,
        size.height - (i * 5).toDouble(),
      );

      canvas.drawLine(start, end, linePaint);
    }

    // Radial Gradient Overlay with Pulse Animation
    final radialGradientPaint = Paint()
      ..shader = RadialGradient(
        colors: Theme.of(context).brightness == Brightness.dark
            ? [
                Colors.white.withOpacity(0.05),
                Colors.transparent,
              ]
            : [
                Colors.black.withOpacity(0.05),
                Colors.transparent,
              ],
        center: Alignment.center,
        radius: 0.5 + math.sin(animation.value * math.pi) * 0.2,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      radialGradientPaint,
    );

    // Food Emojis with Enhanced Effects
    final textStyle = TextStyle(
      fontSize: 24 + (math.sin(animation.value * math.pi) * 4).abs(),
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black,
      shadows: [
        Shadow(
          blurRadius: 8,
          color: Colors.white.withOpacity(0.5),
          offset: const Offset(0, 0),
        ),
      ],
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < dotPositions.length; i++) {
      var newX = dotPositions[i].dx;
      var newY = dotPositions[i].dy;

      if (isTouched) {
        final dx = (newX - touchX);
        final dy = (newY - touchY);
        final distance = math.sqrt(dx * dx + dy * dy);
        const maxDistance = 200.0;
        final explosionForce = (1 - distance / maxDistance) * 15;

        if (distance < maxDistance) {
          final angle = math.atan2(dy, dx);
          newX += math.cos(angle) * explosionForce;
          newY += math.sin(angle) * explosionForce;
        }
      }

      // Apply wave effect
      final waveOffset = math.sin(animation.value * math.pi * 2 + i * 0.5);
      newX += math.cos(animation.value * math.pi * 2 + i) * 2;
      newY += math.sin(animation.value * math.pi * 2 + i) * 2;

      newX += directionX * dotSpeeds[i] * 1 / 7 * animation.value;
      newY += directionY * dotSpeeds[i] * 8 * animation.value;

      dotPositions[i] = Offset(newX % size.width, newY % size.height);

      textPainter.text = TextSpan(
        text: foodEmojis[i],
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, dotPositions[i]);
    }

    // Rotating Gradient Effect
    final rotatingGradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blue.withOpacity(0.3),
          Colors.green.withOpacity(0.3),
          Colors.yellow.withOpacity(0.3),
        ],
        stops: const [0.0, 0.5, 1.0],
        tileMode: TileMode.mirror,
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    final rotatingGradientAnimation = animation.value * 2 * math.pi / 4;
    canvas.save();
    canvas.translate(size.width / 3, size.height / 2);
    canvas.rotate(rotatingGradientAnimation);
    canvas.drawRect(
      Rect.fromLTWH(
        -size.width / 2,
        -size.height / 2,
        size.width,
        size.height,
      ),
      rotatingGradientPaint,
    );
    canvas.restore();

    // Glowing Emoji Effect
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.transparent,
        ],
        radius: 0.5,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < dotPositions.length; i++) {
      canvas.drawCircle(
        Offset(dotPositions[i].dx, dotPositions[i].dy),
        10 + math.sin(animation.value * math.pi) * 5,
        glowPaint,
      );
    }

    // Grid Effect
    final gridPaint = Paint()
      ..color = Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withOpacity(0.02)
          : Colors.black.withOpacity(0.02)
      ..strokeWidth = 0.5;

    for (int i = 0; i < size.width; i += 50) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => true;
}
