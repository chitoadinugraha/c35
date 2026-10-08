import 'package:alienai_c35/c/media/image_generate_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

const _productNameOnly =
    'Photorealistic product photo of es teh, studio lighting, centered, plain background, no text, no logo, no watermark';
const _productNameDesc =
    'Photorealistic product photo of es teh, teh manis dalam gelas plastik, studio lighting, centered, plain background, no text, no logo, no watermark';
const _iconNameOnly =
    'Simple app icon of testing, flat graphic mark, centered, plain background, no text, no letters, no watermark';
const _iconNameDesc =
    'Simple app icon of testing, warung teh, flat graphic mark, centered, plain background, no text, no letters, no watermark';

void main() {
  test('product name only uses the product sentence', () {
    expect(
      imageGenerateDefaultPrompt(
        slot: ImageGenerateSlot.product,
        name: 'es teh',
        desc: '',
      ),
      _productNameOnly,
    );
  });

  test('product name and desc inserts the description', () {
    expect(
      imageGenerateDefaultPrompt(
        slot: ImageGenerateSlot.product,
        name: 'es teh',
        desc: 'teh manis dalam gelas plastik',
      ),
      _productNameDesc,
    );
  });

  test('productExtra matches product name only and name plus desc', () {
    expect(
      imageGenerateDefaultPrompt(
        slot: ImageGenerateSlot.productExtra,
        name: 'es teh',
        desc: '',
      ),
      _productNameOnly,
    );
    expect(
      imageGenerateDefaultPrompt(
        slot: ImageGenerateSlot.productExtra,
        name: 'es teh',
        desc: 'teh manis dalam gelas plastik',
      ),
      _productNameDesc,
    );
  });

  test('siteIcon name only uses the icon sentence', () {
    expect(
      imageGenerateDefaultPrompt(
        slot: ImageGenerateSlot.siteIcon,
        name: 'testing',
        desc: '',
      ),
      _iconNameOnly,
    );
  });

  test('siteIcon name and desc inserts the description', () {
    expect(
      imageGenerateDefaultPrompt(
        slot: ImageGenerateSlot.siteIcon,
        name: 'testing',
        desc: 'warung teh',
      ),
      _iconNameDesc,
    );
  });

  test('whitespace name returns empty', () {
    expect(
      imageGenerateDefaultPrompt(
        slot: ImageGenerateSlot.product,
        name: '   ',
        desc: 'teh manis',
      ),
      '',
    );
    expect(
      imageGenerateDefaultPrompt(
        slot: ImageGenerateSlot.siteIcon,
        name: '\t  ',
      ),
      '',
    );
  });

  test('desc that is only spaces is treated as empty', () {
    expect(
      imageGenerateDefaultPrompt(
        slot: ImageGenerateSlot.product,
        name: 'es teh',
        desc: '   ',
      ),
      _productNameOnly,
    );
    expect(
      imageGenerateDefaultPrompt(
        slot: ImageGenerateSlot.siteIcon,
        name: 'testing',
        desc: ' \n ',
      ),
      _iconNameOnly,
    );
  });
}
