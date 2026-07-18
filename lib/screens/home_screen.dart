import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../theme/app_theme.dart';
import 'voice_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var selectedIndex = 0;
  final stickers = <Uint8List>[];
  var hasNewSticker = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _CreateView(
            onStickerReady: (image) {
              setState(() {
                stickers.add(image);
                hasNewSticker = true;
              });
            },
          ),
          _CollectionView(stickers: stickers),
        ],
      ),
      bottomNavigationBar: _PlayfulBottomNav(
        selectedIndex: selectedIndex,
        showCollectionBadge: hasNewSticker,
        onSelected: (index) {
          setState(() {
            selectedIndex = index;
            if (index == 1) hasNewSticker = false;
          });
        },
      ),
    );
  }
}

class _PlayfulBottomNav extends StatelessWidget {
  const _PlayfulBottomNav({
    required this.selectedIndex,
    required this.showCollectionBadge,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool showCollectionBadge;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            _NavItem(
              selected: selectedIndex == 0,
              label: '作る',
              onTap: () => onSelected(0),
            ),
            _NavItem(
              selected: selectedIndex == 1,
              label: 'コレクション',
              showBadge: showCollectionBadge,
              onTap: () => onSelected(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.label,
    required this.onTap,
    this.showBadge = false,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: selected ? AppColors.deepPink : AppColors.muted,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 15,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (showBadge) ...[
                    const SizedBox(width: 7),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) =>
                          Transform.scale(scale: value, child: child),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.deepPink,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateView extends StatefulWidget {
  const _CreateView({required this.onStickerReady});

  final ValueChanged<Uint8List> onStickerReady;

  @override
  State<_CreateView> createState() => _CreateViewState();
}

class _CreateViewState extends State<_CreateView> {
  final voiceKey = GlobalKey<VoiceSessionPanelState>();
  var conversationStarted = false;
  var isGenerating = false;

  void talk() {
    if (!conversationStarted) {
      setState(() => conversationStarted = true);
    } else {
      voiceKey.currentState?.listen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB9E6FF), Color(0xFFFFF2C8), Color(0xFFFFFCF4)],
          stops: [0, .62, 1],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 300,
              left: 0,
              right: 0,
              child: _CuteEyes(isGenerating: isGenerating),
            ),
            const Positioned(top: 58, left: 34, child: _Sparkle(size: 28)),
            const Positioned(top: 112, right: 48, child: _Sparkle(size: 20)),
            const Positioned(top: 190, left: 95, child: _Sparkle(size: 14)),
            const Positioned(top: 72, right: -22, child: _Cloud(scale: .9)),
            const Positioned(top: 228, left: -48, child: _Cloud(scale: 1.15)),
            if (conversationStarted)
              Positioned(
                top: 72,
                left: 24,
                right: 24,
                child: VoiceSessionPanel(
                  key: voiceKey,
                  onClose: () => setState(() => conversationStarted = false),
                  onStickerReady: widget.onStickerReady,
                  onGeneratingChanged: (value) {
                    if (mounted) setState(() => isGenerating = value);
                  },
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 72),
                child: Semantics(
                  button: true,
                  label: 'シール作りの音声会話を始める',
                  child: GestureDetector(
                    onTap: talk,
                    child: const SizedBox(
                      width: 190,
                      height: 136,
                      child: Center(
                        child: SizedBox(
                          key: Key('mouth-icon'),
                          width: 154,
                          height: 104,
                          child: CustomPaint(painter: _MouthPainter()),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CuteEyes extends StatefulWidget {
  const _CuteEyes({required this.isGenerating});

  final bool isGenerating;

  @override
  State<_CuteEyes> createState() => _CuteEyesState();
}

class _CuteEyesState extends State<_CuteEyes> with TickerProviderStateMixin {
  late final AnimationController blinkController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  late final AnimationController tearController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final AnimationController spinController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  late final Animation<double> blink = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(1), weight: 88),
    TweenSequenceItem(tween: Tween(begin: 1, end: .08), weight: 5),
    TweenSequenceItem(tween: Tween(begin: .08, end: 1), weight: 5),
    TweenSequenceItem(tween: ConstantTween(1), weight: 2),
  ]).animate(CurvedAnimation(parent: blinkController, curve: Curves.easeInOut));

  var tapCount = 0;
  var crying = false;
  var reactionId = 0;

  @override
  void didUpdateWidget(covariant _CuteEyes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGenerating == oldWidget.isGenerating) return;
    if (widget.isGenerating) {
      spinController.repeat();
    } else {
      spinController.stop();
      spinController.reset();
    }
  }

  void onEyeTap() {
    tapCount += 1;
    if (tapCount < 3) return;

    tapCount = 0;
    reactionId += 1;
    final currentReaction = reactionId;
    setState(() => crying = true);
    tearController.repeat();

    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!mounted || currentReaction != reactionId) return;
      tearController.stop();
      tearController.reset();
      setState(() => crying = false);
    });
  }

  @override
  void dispose() {
    blinkController.dispose();
    tearController.dispose();
    spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: '目',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onEyeTap,
            child: SizedBox(
              width: 250,
              height: 120,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CuteEye(
                        isGenerating: widget.isGenerating,
                        spin: spinController,
                      ),
                      const SizedBox(width: 50),
                      _CuteEye(
                        isGenerating: widget.isGenerating,
                        spin: spinController,
                      ),
                    ],
                  ),
                  Positioned(
                    left: 4,
                    top: 0,
                    child: _BlinkingLid(animation: blink),
                  ),
                  Positioned(
                    right: 4,
                    top: 0,
                    child: _BlinkingLid(animation: blink),
                  ),
                  if (crying) ...[
                    Positioned(
                      left: 53,
                      top: 72,
                      child: _FallingTear(animation: tearController),
                    ),
                    Positioned(
                      right: 53,
                      top: 72,
                      child: _FallingTear(
                        animation: tearController,
                        delay: .42,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_Cheek(), SizedBox(width: 182), _Cheek()],
        ),
      ],
    );
  }
}

class _BlinkingLid extends StatelessWidget {
  const _BlinkingLid({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 96,
        height: 116,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(54),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final closed = 1 - animation.value;
              final lidHeight = 58 * closed;
              return Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(height: lidHeight, color: Colors.white),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(height: lidHeight, color: Colors.white),
                  ),
                  if (closed > .72)
                    Center(
                      child: Container(
                        width: 64,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FallingTear extends StatelessWidget {
  const _FallingTear({required this.animation, this.delay = 0});

  final Animation<double> animation;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = (animation.value + delay) % 1;
        return Opacity(
          opacity: (1 - progress).clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, progress * 54),
            child: child,
          ),
        );
      },
      child: const Icon(
        Icons.water_drop_rounded,
        color: Color(0xFF70C7F4),
        size: 29,
      ),
    );
  }
}

class _CuteEye extends StatelessWidget {
  const _CuteEye({required this.isGenerating, required this.spin});

  final bool isGenerating;
  final Animation<double> spin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 116,
      foregroundDecoration: const _LashDecoration(),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(54),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22997BD8),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 60,
          height: 76,
          decoration: BoxDecoration(
            color: isGenerating ? Colors.transparent : AppColors.ink,
            shape: BoxShape.circle,
          ),
          child: isGenerating
              ? RotationTransition(
                  turns: spin,
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: CustomPaint(painter: _SpiralPainter()),
                  ),
                )
              : Stack(
                  children: [
                    const Positioned(
                      top: 7,
                      left: 7,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),
                    Positioned(
                      right: 11,
                      bottom: 13,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.sky,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 13,
                      bottom: 11,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LashDecoration extends Decoration {
  const _LashDecoration();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _LashPainter();
}

class _LashPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size ?? Size.zero;
    final paint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final lashes = [
      (const Offset(12, 12), const Offset(2, 1)),
      (const Offset(20, 7), const Offset(14, -5)),
      (const Offset(29, 4), const Offset(27, -9)),
      (Offset(size.width - 12, 12), Offset(size.width + 2, 1)),
      (Offset(size.width - 20, 7), Offset(size.width - 14, -5)),
      (Offset(size.width - 29, 4), Offset(size.width - 27, -9)),
    ];

    for (final lash in lashes) {
      canvas.drawLine(offset + lash.$1, offset + lash.$2, paint);
    }
  }
}

class _SpiralPainter extends CustomPainter {
  const _SpiralPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();
    const turns = 2.65;
    const points = 90;

    for (var index = 0; index <= points; index += 1) {
      final progress = index / points;
      final angle = progress * turns * math.pi * 2;
      final radius = 2 + progress * (size.shortestSide * .4);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Cheek extends StatelessWidget {
  const _Cheek();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 16,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome, color: Colors.white, size: size);
  }
}

class _Cloud extends StatelessWidget {
  const _Cloud({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: const Icon(
        Icons.cloud_rounded,
        color: Color(0xDDFFFFFF),
        size: 104,
      ),
    );
  }
}

class _MouthPainter extends CustomPainter {
  const _MouthPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final lip = Paint()
      ..color = AppColors.deepPink
      ..style = PaintingStyle.fill;

    final mouth = Path()
      ..moveTo(2, center.dy)
      ..cubicTo(
        size.width * .24,
        0,
        size.width * .39,
        size.height * .18,
        center.dx,
        size.height * .27,
      )
      ..cubicTo(
        size.width * .61,
        size.height * .18,
        size.width * .76,
        0,
        size.width - 2,
        center.dy,
      )
      ..cubicTo(
        size.width * .72,
        size.height,
        size.width * .28,
        size.height,
        2,
        center.dy,
      )
      ..close();

    canvas.drawPath(mouth, lip);
    canvas.drawLine(
      Offset(5, center.dy),
      Offset(size.width - 5, center.dy),
      Paint()
        ..color = const Color(0xFFFFE8F0)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CollectionView extends StatelessWidget {
  const _CollectionView({required this.stickers});

  final List<Uint8List> stickers;

  Future<Uint8List> makeFourUpSheet(Uint8List selected) async {
    const canvasWidth = 2048.0;
    const canvasHeight = 2440.0;
    const outerMargin = 96.0;
    const gap = 64.0;
    const gridTop = 292.0;
    const tileSize = (canvasWidth - outerMargin * 2 - gap) / 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      Paint()..color = const Color(0xFFFFFBEC),
    );

    void drawText(
      String text,
      Offset center,
      double fontSize,
      Color color, {
      FontWeight weight = FontWeight.w800,
    }) {
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: fontSize,
          fontWeight: weight,
        ),
      )..pushStyle(ui.TextStyle(color: color));
      builder.addText(text);
      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: canvasWidth));
      canvas.drawParagraph(
        paragraph,
        Offset(
          center.dx - paragraph.longestLine / 2,
          center.dy - paragraph.height / 2,
        ),
      );
    }

    void drawPill(Rect rect, Color color) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(72)),
        Paint()..color = color,
      );
    }

    void drawDashedLine(Offset start, Offset end) {
      final paint = Paint()
        ..color = const Color(0xFFCFBFAF)
        ..strokeWidth = 4;
      final distance = (end - start).distance;
      final direction = (end - start) / distance;
      const dash = 18.0;
      const space = 14.0;
      for (var position = 0.0; position < distance; position += dash + space) {
        canvas.drawLine(
          start + direction * position,
          start + direction * math.min(position + dash, distance),
          paint,
        );
      }
    }

    drawPill(const Rect.fromLTWH(650, 54, 748, 154), const Color(0xFFFFD7E4));
    drawPill(const Rect.fromLTWH(92, 86, 430, 104), const Color(0xFFC9F1E3));
    drawPill(const Rect.fromLTWH(1526, 86, 430, 104), const Color(0xFFCDEBFF));
    drawText(
      'ぺたっと',
      const Offset(canvasWidth / 2, 131),
      92,
      AppColors.deepPink,
      weight: FontWeight.w900,
    );
    drawText('できたよ！', const Offset(307, 138), 44, AppColors.ink);
    drawText('きってつかおう', const Offset(1741, 138), 39, AppColors.ink);

    final codec = await ui.instantiateImageCodec(selected);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final sourceSide = math.min(image.width, image.height).toDouble();
    final source = Rect.fromCenter(
      center: Offset(image.width / 2, image.height / 2),
      width: sourceSide,
      height: sourceSide,
    );

    for (var index = 0; index < 4; index += 1) {
      final column = index % 2;
      final row = index ~/ 2;
      final destination = Rect.fromLTWH(
        outerMargin + column * (tileSize + gap),
        gridTop + row * (tileSize + gap),
        tileSize,
        tileSize,
      );
      canvas.drawImageRect(
        image,
        source,
        destination,
        Paint()..filterQuality = FilterQuality.high,
      );
    }
    image.dispose();
    codec.dispose();

    final gridBottom = gridTop + tileSize * 2 + gap;
    drawDashedLine(
      Offset(canvasWidth / 2, gridTop - 20),
      Offset(canvasWidth / 2, gridBottom + 20),
    );
    drawDashedLine(
      Offset(outerMargin - 20, gridTop + tileSize + gap / 2),
      Offset(canvasWidth - outerMargin + 20, gridTop + tileSize + gap / 2),
    );

    drawPill(
      Rect.fromLTWH(290, gridBottom + 58, 1468, 116),
      const Color(0xFFFFE5A8),
    );
    drawText(
      'すきなところに はってね！',
      Offset(canvasWidth / 2, gridBottom + 116),
      48,
      AppColors.ink,
      weight: FontWeight.w900,
    );
    drawText(
      '✦  はさみでゆっくりきってね  ✦',
      Offset(canvasWidth / 2, gridBottom + 210),
      34,
      AppColors.muted,
      weight: FontWeight.w700,
    );

    final sheet = await recorder.endRecording().toImage(2048, 2440);
    final data = await sheet.toByteData(format: ui.ImageByteFormat.png);
    sheet.dispose();
    if (data == null) throw StateError('Could not create print sheet');
    return data.buffer.asUint8List();
  }

  Future<void> saveSticker(BuildContext context, Uint8List bytes) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Gal.putImageBytes(
        bytes,
        album: 'シールコレクション',
        name: 'sticker-${DateTime.now().millisecondsSinceEpoch}',
      );
      messenger.showSnackBar(const SnackBar(content: Text('写真に保存しました')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('保存できませんでした')));
    }
  }

  Future<void> saveFourUpSticker(BuildContext context, Uint8List bytes) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final printSheet = await makeFourUpSheet(bytes);
      await Gal.putImageBytes(
        printSheet,
        album: 'シールコレクション',
        name: 'sticker-4up-${DateTime.now().millisecondsSinceEpoch}',
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('4枚の切り取り用画像を保存しました')),
      );
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('4枚の画像を保存できませんでした')));
    }
  }

  void showSticker(BuildContext context, Uint8List bytes) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xDD282536),
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: .8,
                  maxScale: 4,
                  child: Hero(
                    tag: bytes,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.ink,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Builder(
                  builder: (buttonContext) => IconButton.filled(
                    onPressed: () => saveFourUpSticker(buttonContext, bytes),
                    icon: const Icon(Icons.content_copy_rounded),
                    tooltip: '同じシールを4枚にして保存',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.deepPink,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 64,
                child: Builder(
                  builder: (buttonContext) => IconButton.filled(
                    onPressed: () => saveSticker(buttonContext, bytes),
                    icon: const Icon(Icons.download_rounded),
                    tooltip: 'このシール1枚を保存',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: stickers.isEmpty
          ? const Center(
              child: Text(
                'まだシールがありません',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Text(
                    'できたシール  ${stickers.length}枚',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      height: 180,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        itemCount: stickers.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 18),
                        itemBuilder: (context, index) {
                          final bytes = stickers[index];
                          return _CollectionSticker(
                            bytes: bytes,
                            onTap: () => showSticker(context, bytes),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CollectionSticker extends StatelessWidget {
  const _CollectionSticker({required this.bytes, required this.onTap});

  final Uint8List bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: bytes,
        child: Container(
          width: 164,
          height: 164,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: Colors.white, width: 7),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22936DB8),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
