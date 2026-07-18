import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../theme/app_theme.dart';
import '../services/sticker_api.dart';

class VoiceSessionPanel extends StatefulWidget {
  const VoiceSessionPanel({
    super.key,
    required this.onClose,
    required this.onStickerReady,
    required this.onGeneratingChanged,
  });

  final VoidCallback onClose;
  final ValueChanged<Uint8List> onStickerReady;
  final ValueChanged<bool> onGeneratingChanged;

  @override
  State<VoiceSessionPanel> createState() => VoiceSessionPanelState();
}

class VoiceSessionPanelState extends State<VoiceSessionPanel> {
  static const questions = [
    'どんな生き物や、ものを作りたい？',
    '体はどんな形にしたい？',
    '何色にしたい？',
    '顔や目はどんな感じ？',
    'どんな性格の子にする？',
  ];

  final speech = SpeechToText();
  final tts = FlutterTts();
  final answers = <String>[];
  final chatHistory = <Map<String, String>>[];
  var questionIndex = 0;
  var transcript = '';
  var status = '準備中…';
  var available = false;
  var showStickerPreview = false;
  var notified = false;
  var isGenerating = false;
  var isChatting = false;
  Future<void> ttsQueue = Future<void>.value();
  Uint8List? stickerBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => startSession());
  }

  Future<void> startSession() async {
    available = await speech.initialize(
      onStatus: (value) {
        if (mounted && value == 'notListening' && transcript.isEmpty) {
          setState(() => status = '口を押して話してね');
        }
      },
      onError: (_) {
        if (mounted) setState(() => status = 'もう一度、口を押してね');
      },
    );
    if (!available) {
      if (mounted) setState(() => status = 'マイクを許可してね');
      return;
    }
    await tts.setLanguage('ja-JP');
    await tts.setSpeechRate(.46);
    await tts.awaitSpeakCompletion(true);
    await askCurrentQuestion();
  }

  Future<void> askCurrentQuestion() async {
    if (!mounted) return;
    setState(() {
      transcript = '';
      status = 'AIが話しているよ';
    });
    await say(questions[questionIndex]);
    await listen();
  }

  Future<void> say(String text) {
    final next = ttsQueue.then((_) async {
      if (!mounted) return;
      await tts.speak(text);
    });
    ttsQueue = next.catchError((_) {});
    return next;
  }

  Future<void> listen() async {
    if (!available || speech.isListening || isChatting) {
      return;
    }
    if (answers.length == questions.length && !isGenerating) {
      return;
    }
    if (mounted) setState(() => status = '話してね');
    await speech.listen(
      onResult: onSpeechResult,
      listenOptions: SpeechListenOptions(
        localeId: 'ja_JP',
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 5),
        listenMode: ListenMode.dictation,
        autoPunctuation: true,
      ),
    );
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() => transcript = result.recognizedWords);
    if (result.finalResult && transcript.isNotEmpty) {
      if (isGenerating) {
        final message = transcript;
        handleGeneratingConversation(message);
        return;
      }
      answers.add(transcript);
      if (questionIndex < questions.length - 1) {
        questionIndex += 1;
        Future<void>.delayed(
          const Duration(milliseconds: 500),
          askCurrentQuestion,
        );
      } else {
        generateSticker();
      }
    }
  }

  Future<void> handleGeneratingConversation(String message) async {
    if (isChatting) return;
    setState(() {
      isChatting = true;
      status = 'AIがかんがえているよ…';
    });
    try {
      final reply = await StickerApi.chatAboutSticker(
        answers: answers,
        message: message,
        history: chatHistory,
      );
      chatHistory.add({'role': 'user', 'content': message});
      chatHistory.add({'role': 'assistant', 'content': reply});
      if (!mounted) return;
      if (!isGenerating) {
        setState(() => isChatting = false);
        return;
      }
      setState(() {
        status = reply;
        isChatting = false;
      });
      await say(reply);
    } catch (_) {
      if (!mounted) return;
      if (!isGenerating) {
        setState(() => isChatting = false);
        return;
      }
      setState(() {
        status = 'うん、すてき！ もう一回おしえて？';
        isChatting = false;
      });
      await say('うん、すてき！ もう一回おしえて？');
    }
    if (mounted && isGenerating) await listen();
  }

  Future<void> generateSticker() async {
    setState(() {
      isGenerating = true;
      transcript = '';
      status = 'シールを作っているよ…';
    });
    widget.onGeneratingChanged(true);
    final imageFuture = StickerApi.generate(answers);
    await say('ありがとう。すてきなシールを作るね。待っている間も、口を押してお話しできるよ。');
    if (mounted) await listen();
    try {
      final image = await imageFuture;
      if (!mounted) return;
      await speech.stop();
      setState(() {
        isGenerating = false;
        stickerBytes = image;
        status = 'シールができたよ！';
        showStickerPreview = true;
      });
      widget.onGeneratingChanged(false);
      await say('シールができたよ！ とってもすてきにできたよ。');
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted || notified) return;
      notified = true;
      setState(() {
        showStickerPreview = false;
        status = 'コレクションに入れたよ！';
      });
      widget.onStickerReady(image);
    } catch (_) {
      isGenerating = false;
      widget.onGeneratingChanged(false);
      if (mounted) setState(() => status = 'うまく作れなかったよ。もう一度話してね');
    }
  }

  @override
  void dispose() {
    speech.stop();
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finished = answers.length == questions.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22936DB8),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    isGenerating
                        ? 'つくっているよ'
                        : finished
                        ? 'できあがり'
                        : '${questionIndex + 1} / ${questions.length}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (showStickerPreview) ...[
                const SizedBox(height: 12),
                _StickerPreview(bytes: stickerBytes!),
              ] else ...[
                const SizedBox(height: 5),
                Text(
                  isGenerating
                      ? '口を押して、シールのお話をしよう'
                      : finished
                      ? 'コレクションを見てみよう'
                      : questions[questionIndex],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (transcript.isNotEmpty && !showStickerPreview) ...[
                const SizedBox(height: 8),
                Text(
                  '「$transcript」',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ],
          ),
        ),
        const CustomPaint(size: Size(30, 16), painter: _BubbleTailPainter()),
      ],
    );
  }
}

class _StickerPreview extends StatelessWidget {
  const _StickerPreview({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Transform.rotate(angle: (1 - value) * -.18, child: child),
      ),
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.yellow, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white, width: 6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22936DB8),
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFDFDFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
