import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';

String liveOfferLabel(LiveOffer offer) {
  final key = offer.labelKey.isNotEmpty ? offer.labelKey : offer.label;
  if (key.startsWith('live.') && key.endsWith('.label')) {
    final en = catalogLocaleFallback('en')[key];
    if (en != null && en.isNotEmpty) return en;
  }
  if (key.isEmpty) return offer.id;
  final t = catalogT(key);
  return t != key ? t : (offer.label.isNotEmpty ? offer.label : offer.id);
}

String liveOfferPricePerMinLocal(
  LiveOffer offer, {
  required String currency,
  required int fxMicroPerUsd,
}) =>
    moneyUsdPerMinLabel(offer.retailUsdPerMin, currency: currency, fxMicroPerUsd: fxMicroPerUsd);

String liveOfferSoonTag() => catalogT('live.soon');

String liveOfferMenuLabel(LiveOffer offer) =>
    offer.enabled ? liveOfferLabel(offer) : '${liveOfferLabel(offer)} (${liveOfferSoonTag()})';

List<LiveOffer> liveOffersOfflineFallback() => [
      LiveOffer(
        id: 'live.alienai',
        family: 'alienai',
        labelKey: 'live.alienai.label',
        provider: 'google',
        enabled: true,
        retailUsdPerMin: 0.0345,
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
        inputUsdPerMin: 0.005,
        outputUsdPerMin: 0.018,
      ),
      LiveOffer(
        id: 'live.chatgpt',
        family: 'openai',
        labelKey: 'live.chatgpt.label',
        provider: 'openai',
        enabled: false,
        retailUsdPerMin: 0.045,
      ),
      LiveOffer(
        id: 'live.grok',
        family: 'xai',
        labelKey: 'live.grok.label',
        provider: 'xai',
        enabled: false,
        retailUsdPerMin: 0.045,
      ),
    ];
