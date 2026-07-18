import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

abstract final class StickerApi {
  static const apiKey = String.fromEnvironment('OPENAI_API_KEY');

  static Future<Uint8List> generate(List<String> answers) async {
    if (apiKey.isEmpty) throw StateError('OPENAI_API_KEY is not configured');
    final fields = [...answers, '', '', '', '', ''];
    final spec = {
      'creature': fields[0],
      'body_shape': fields[1],
      'color': fields[2],
      'face_and_eyes': fields[3],
      'personality': fields[4],
    };

    final prompt =
        '''
添付されたCharacterSpecを厳密に参照する。

CharacterSpec:
${jsonEncode(spec)}

正方形のコレクションシール用イラストを作成する。

条件：
- キャラクターのデザインをCharacterSpecから変更しない
- キャラクターを中央に大きく配置
- 周囲に十分な余白を残す
- レトロでキラキラしたオリジナルのコレクションシール風
- 細かな光、箔、星、花などの装飾
- 既存ブランドのロゴや既存商品の構図を使用しない
- 既存作品や既存キャラクターを模倣しない
- タイトル、文章、ロゴ、切り取り線は描かない
- キャラクター全体が切れない
- 6〜10歳の子ども向けの、明るく親しみやすいデザイン
- 正方形、高精細
''';

    final response = await http
        .post(
          Uri.parse('https://api.openai.com/v1/images/generations'),
          headers: {
            'authorization': 'Bearer $apiKey',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': 'gpt-image-2',
            'prompt': prompt,
            'size': '1024x1024',
            'quality': 'medium',
            'output_format': 'png',
          }),
        )
        .timeout(const Duration(minutes: 3));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw StateError(
        (body['error'] as Map<String, dynamic>?)?['message'] as String? ??
            'Image generation failed',
      );
    }
    final image = (body['data'] as List).first as Map<String, dynamic>;
    return base64Decode(image['b64_json'] as String);
  }

  static Future<String> chatAboutSticker({
    required List<String> answers,
    required String message,
    required List<Map<String, String>> history,
  }) async {
    if (apiKey.isEmpty) throw StateError('OPENAI_API_KEY is not configured');
    final fields = [...answers, '', '', '', '', ''];
    final character = {
      'creature': fields[0],
      'body_shape': fields[1],
      'color': fields[2],
      'face_and_eyes': fields[3],
      'personality': fields[4],
    };
    final recentHistory = history.length > 6
        ? history.sublist(history.length - 6)
        : history;

    final response = await http
        .post(
          Uri.parse('https://api.openai.com/v1/responses'),
          headers: {
            'authorization': 'Bearer $apiKey',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': 'gpt-4.1-mini',
            'instructions': '''
あなたは6〜10歳の子どもと一緒にシールを作る、明るく優しい会話係です。
現在は画像の生成中です。CharacterSpecを踏まえて、作っているキャラクターのことを楽しく話してください。
- 子どもに分かる短い日本語で、2文以内
- 子どもの表現を否定しない
- 個人情報は聞かない
- キャラクターの色、形、顔、性格と矛盾しない
- 画像が完成したとは言わない
''',
            'input':
                '''
CharacterSpec: ${jsonEncode(character)}
直近の会話: ${jsonEncode(recentHistory)}
子ども: $message
''',
            'max_output_tokens': 100,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw StateError(
        (body['error'] as Map<String, dynamic>?)?['message'] as String? ??
            'Conversation failed',
      );
    }
    final output = body['output'] as List<dynamic>? ?? const [];
    for (final item in output) {
      final content =
          (item as Map<String, dynamic>)['content'] as List<dynamic>?;
      if (content == null) continue;
      for (final part in content) {
        final value = part as Map<String, dynamic>;
        if (value['type'] == 'output_text' && value['text'] is String) {
          return value['text'] as String;
        }
      }
    }
    throw StateError('Conversation returned no text');
  }
}
