import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';

String liveCallVerb() {
  final t = catalogT('live.call.verb');
  return t != 'live.call.verb' ? t : 'Call';
}

String liveCallGenericChipTitle() {
  final t = catalogT('live.chip.generic');
  return t != 'live.chip.generic' ? t : '${liveCallVerb()} AI';
}

String liveOfferLabel(LiveOffer offer) {
  final key = offer.labelKey.isNotEmpty ? offer.labelKey : offer.label;
  if (key.isEmpty) return offer.id;
  final t = catalogT(key);
  return t != key ? t : (offer.label.isNotEmpty ? offer.label : offer.id);
}

String liveOfferBrandLabel(LiveOffer offer) {
  var brand = liveOfferLabel(offer).trim();
  for (final prefix in ['Call ', 'Telepon ']) {
    if (brand.length > prefix.length && brand.startsWith(prefix)) {
      brand = brand.substring(prefix.length).trim();
      break;
    }
  }
  return brand.isEmpty ? liveOfferLabel(offer) : brand;
}

String liveOfferActionTitle(LiveOffer offer) => '${liveCallVerb()} ${liveOfferBrandLabel(offer)}';

String liveOfferPricePerMinLocal(
  LiveOffer offer, {
  required String currency,
  required int fxMicroPerUsd,
}) =>
    moneyUsdPerMinLabel(offer.retailUsdPerMin, currency: currency, fxMicroPerUsd: fxMicroPerUsd);

String liveOfferPricePerSecLocal(
  LiveOffer offer, {
  required String currency,
  required int fxMicroPerUsd,
}) =>
    moneyUsdPerSecLabel(offer.retailUsdPerMin, currency: currency, fxMicroPerUsd: fxMicroPerUsd);

String liveOfferPricePerSecDualLocal(
  LiveOffer offer, {
  required String currency,
  required int fxMicroPerUsd,
}) {
  final voice = moneyUsdPerSecLabel(offer.retailUsdPerMin, currency: currency, fxMicroPerUsd: fxMicroPerUsd);
  final videoRate = offer.retailVideoUsdPerMin > 0
      ? offer.retailVideoUsdPerMin
      : (offer.retailUsdPerMin + 0.002325);
  final video = moneyUsdPerSecLabel(videoRate, currency: currency, fxMicroPerUsd: fxMicroPerUsd);
  final voiceLabel = catalogT('live.price.voice');
  final videoLabel = catalogT('live.price.video');
  final vTitle = voiceLabel != 'live.price.voice' ? voiceLabel : 'Voice';
  final vidTitle = videoLabel != 'live.price.video' ? videoLabel : 'Video';
  return '$vTitle: $voice  ·  $vidTitle: $video';
}

String liveOfferSoonTag() => catalogT('live.soon');

String liveOfferMenuLabel(LiveOffer offer) => offer.enabled
    ? liveOfferActionTitle(offer)
    : '${liveOfferActionTitle(offer)} (${liveOfferSoonTag()})';

List<LiveOffer> liveOffersOfflineFallback() => [
      LiveOffer(
        id: 'live.alienai',
        family: 'alienai',
        labelKey: 'live.alienai.label',
        provider: 'google',
        enabled: true,
        retailUsdPerMin: 0.0345,
        retailVideoUsdPerMin: 0.0368,
        inputUsdPerMin: 0.005,
        outputUsdPerMin: 0.018,
      ),
      LiveOffer(
        id: 'live.gemini',
        family: 'gemini',
        labelKey: 'live.gemini.label',
        provider: 'google',
        enabled: true,
        retailUsdPerMin: 0.0345,
        retailVideoUsdPerMin: 0.0368,
        inputUsdPerMin: 0.005,
        outputUsdPerMin: 0.018,
      ),
      LiveOffer(
        id: 'live.gemini.thinker',
        family: 'gemini',
        labelKey: 'live.gemini.thinker.label',
        provider: 'google',
        enabled: true,
        retailUsdPerMin: 0.0345,
        retailVideoUsdPerMin: 0.0368,
        inputUsdPerMin: 0.005,
        outputUsdPerMin: 0.018,
      ),
      LiveOffer(
        id: 'live.chatgpt',
        family: 'openai',
        labelKey: 'live.chatgpt.label',
        provider: 'openai',
        enabled: true,
        retailUsdPerMin: 0.045,
        retailVideoUsdPerMin: 0.08325,
        inputUsdPerMin: 0.006,
        outputUsdPerMin: 0.024,
      ),
      LiveOffer(
        id: 'live.grok',
        family: 'xai',
        labelKey: 'live.grok.label',
        provider: 'xai',
        enabled: true,
        retailUsdPerMin: 0.045,
        retailVideoUsdPerMin: 0.0525,
        inputUsdPerMin: 0.006,
        outputUsdPerMin: 0.024,
      ),
    ];
