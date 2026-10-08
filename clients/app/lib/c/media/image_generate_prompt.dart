enum ImageGenerateSlot { product, productExtra, siteIcon }

String imageGenerateDefaultPrompt({
  required ImageGenerateSlot slot,
  required String name,
  String desc = '',
}) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) return '';
  final trimmedDesc = desc.trim();
  switch (slot) {
    case ImageGenerateSlot.product:
    case ImageGenerateSlot.productExtra:
      if (trimmedDesc.isEmpty) {
        return 'Photorealistic product photo of $trimmedName, studio lighting, centered, plain background, no text, no logo, no watermark';
      }
      return 'Photorealistic product photo of $trimmedName, $trimmedDesc, studio lighting, centered, plain background, no text, no logo, no watermark';
    case ImageGenerateSlot.siteIcon:
      if (trimmedDesc.isEmpty) {
        return 'Simple app icon of $trimmedName, flat graphic mark, centered, plain background, no text, no letters, no watermark';
      }
      return 'Simple app icon of $trimmedName, $trimmedDesc, flat graphic mark, centered, plain background, no text, no letters, no watermark';
  }
}
