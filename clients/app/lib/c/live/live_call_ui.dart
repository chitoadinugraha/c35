import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';

enum LiveCallFamily { alienai, gemini, openai, xai, other }

LiveCallFamily liveCallFamily(AgentModel model) => switch (model.provider) {
      'alienai' => LiveCallFamily.alienai,
      'google' => LiveCallFamily.gemini,
      'openai' => LiveCallFamily.openai,
      'xai' => LiveCallFamily.xai,
      _ => LiveCallFamily.other,
    };

String liveCallPrimaryLabelKey(AgentModel model) => switch (liveCallFamily(model)) {
      LiveCallFamily.alienai => 'live.alienai.label',
      LiveCallFamily.gemini => 'live.gemini.label',
      LiveCallFamily.openai => 'live.chatgpt.label',
      LiveCallFamily.xai => 'live.grok.label',
      LiveCallFamily.other => 'home.liveCall',
    };

String liveCallPrimaryLabel(AgentModel model) {
  final key = liveCallPrimaryLabelKey(model);
  if (key.startsWith('live.') && key.endsWith('.label')) {
    final en = catalogLocaleFallback('en')[key];
    if (en != null && en.isNotEmpty) return en;
  }
  final t = catalogT(key);
  return t != key ? t : key;
}

List<LiveOffer> liveCallMenuOffers(List<LiveOffer> all, AgentModel model) {
  final rows = all.where((o) => o.id.isNotEmpty).toList();
  final enabled = rows.where((o) => o.enabled).toList();
  final familyRows = switch (liveCallFamily(model)) {
    LiveCallFamily.gemini => rows.where((o) => o.family == 'gemini'),
    LiveCallFamily.openai => rows.where((o) => o.family == 'openai'),
    LiveCallFamily.xai => rows.where((o) => o.family == 'xai'),
    LiveCallFamily.alienai => rows.where((o) => o.family == 'alienai'),
    LiveCallFamily.other => rows.where((o) => o.enabled),
  };
  final menu = familyRows.toList();
  if (menu.isNotEmpty) return menu;
  return enabled.isNotEmpty ? enabled : rows;
}

LiveOffer? liveCallDefaultOffer(List<LiveOffer> menu, AgentModel model) {
  if (menu.isEmpty) return null;
  if (liveCallFamily(model) == LiveCallFamily.gemini) {
    for (final o in menu) {
      if (o.id == 'live.gemini') return o;
    }
  }
  return menu.first;
}

double liveCallMenuMinRetail(List<LiveOffer> menu) {
  var min = 0.0;
  var any = false;
  for (final o in menu) {
    if (o.retailUsdPerMin <= 0) continue;
    any = true;
    if (min <= 0 || o.retailUsdPerMin < min) min = o.retailUsdPerMin;
  }
  return any ? min : 0;
}

String liveCallPrimaryPriceLabel(List<LiveOffer> menu) {
  final min = liveCallMenuMinRetail(menu);
  if (min.isInfinite || min <= 0) return '';
  final s = min >= 0.1 ? min.toStringAsFixed(2) : min.toStringAsFixed(3);
  return '~\$$s/min';
}
