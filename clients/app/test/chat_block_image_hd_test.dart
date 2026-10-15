import 'package:alienai_c35/c/chat/chat_block.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatBlock image HD upgrade', () {
    ChatBlock img({required String tool, String prompt = 'a cat', String quality = 'draft', String? imageSize}) {
      return ChatBlock(
        kind: 'image',
        collapsed: false,
        body: {
          'hash': 'abc',
          'tool': tool,
          'prompt': prompt,
          if (quality.isNotEmpty) 'quality': quality,
          if (imageSize != null) 'image_size': imageSize,
        },
      );
    }

    test('allows draft img.generate with prompt', () {
      expect(ChatBlock.imageCanUpgradeHd(img(tool: 'img.generate')), isTrue);
    });

    test('allows img.edit', () {
      expect(ChatBlock.imageCanUpgradeHd(img(tool: 'img.edit')), isTrue);
    });

    test('rejects already HD', () {
      expect(ChatBlock.imageCanUpgradeHd(img(tool: 'img.generate', quality: 'hd')), isFalse);
      expect(ChatBlock.imageCanUpgradeHd(img(tool: 'img.generate', imageSize: '2K')), isFalse);
    });

    test('rejects device and other tools', () {
      expect(ChatBlock.imageCanUpgradeHd(img(tool: 'device.result', prompt: 'Result on device')), isFalse);
      expect(ChatBlock.imageCanUpgradeHd(img(tool: 'device.som', prompt: '')), isFalse);
      expect(ChatBlock.imageCanUpgradeHd(img(tool: '', prompt: 'x')), isFalse);
    });

    test('rejects empty prompt', () {
      expect(ChatBlock.imageCanUpgradeHd(img(tool: 'img.generate', prompt: '')), isFalse);
    });

    test('imageFirstUpgradeable skips ineligible blocks', () {
      final json = ChatBlock.encodeList([
        img(tool: 'device.result', prompt: 'Result on device'),
        img(tool: 'img.generate', prompt: 'logo'),
      ]);
      final picked = ChatBlock.imageFirstUpgradeable(json);
      expect(picked, isNotNull);
      expect(ChatBlock.mediaTool(picked!), 'img.generate');
    });
  });
}
