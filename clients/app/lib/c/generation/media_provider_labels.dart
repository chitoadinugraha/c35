import 'package:easy_localization/easy_localization.dart';

class MediaProviderOption {
  const MediaProviderOption({required this.id, required this.labelKey, this.estimatedUsd, this.iconProvider = ''});

  final String id;
  final String labelKey;
  final double? estimatedUsd;
  final String iconProvider;

  String get label => labelKey.tr();
}

String mediaBlockKind(String blockKind) => switch (blockKind) {
      'video' => 'video',
      'music' || 'audio' => 'music',
      _ => 'image',
    };

List<MediaProviderOption> mediaProviderOptionsForKind(String kind) => switch (kind) {
      'video' => const [
          MediaProviderOption(id: 'auto', labelKey: 'media.providerAuto'),
          MediaProviderOption(id: 'gemini', labelKey: 'media.providerGemini', iconProvider: 'google', estimatedUsd: 0.27),
          MediaProviderOption(id: 'seedance', labelKey: 'media.providerSeedance', estimatedUsd: 0.18),
        ],
      'music' => const [
          MediaProviderOption(id: 'auto', labelKey: 'media.providerAuto'),
          MediaProviderOption(id: 'gemini', labelKey: 'media.providerGemini', iconProvider: 'google', estimatedUsd: 0.09),
          MediaProviderOption(id: 'minimax', labelKey: 'media.providerMinimax', estimatedUsd: 0.23),
          MediaProviderOption(id: 'elevenlabs', labelKey: 'media.providerElevenlabs', estimatedUsd: 0.12),
        ],
      _ => const [
          MediaProviderOption(id: 'auto', labelKey: 'media.providerAuto'),
          MediaProviderOption(id: 'gemini', labelKey: 'media.providerGemini', iconProvider: 'google', estimatedUsd: 0.05),
          MediaProviderOption(id: 'grok', labelKey: 'media.providerGrok', iconProvider: 'xai', estimatedUsd: 0.03),
        ],
    };

MediaProviderOption? mediaProviderOptionFind(String kind, String id) {
  final slug = id.trim().toLowerCase();
  for (final o in mediaProviderOptionsForKind(kind)) {
    if (o.id == slug) return o;
  }
  return null;
}

String mediaProviderLabel(String kind, String providerId) =>
    mediaProviderOptionFind(kind, providerId)?.label ?? providerId;

String mediaGeneratedWithLabel(String kind, String providerId) =>
    'media.generatedWith'.tr(namedArgs: {'provider': mediaProviderLabel(kind, providerId)});

String mediaEstimatedCostLabel(double? usd, {String billingCurrency = 'USD'}) {
  if (usd == null) return '';
  final amount = billingCurrency.toUpperCase() == 'IDR' ? usd.toStringAsFixed(0) : '\$${usd.toStringAsFixed(2)}';
  return 'media.estimatedCost'.tr(namedArgs: {'cost': amount});
}
