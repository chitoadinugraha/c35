import 'package:alienai_c35/c/pb/c35/session.pb.dart';
import 'package:flutter/material.dart';

enum AgentThinking {
  off,
  low,
  medium,
  high;

  String get wire => name;
  String get label => switch (this) { off => 'Fastest', low => 'Fast', medium => 'Medium', high => 'Deep' };
  String get badge => switch (this) { medium => 'Med', _ => label };
  String get hint => switch (this) {
        off => 'Fastest reply',
        low => 'Light thinking',
        medium => 'Balanced thinking',
        high => 'Deepest reasoning',
      };
  String get tooltip => 'Thinking Level: $hint';
  static AgentThinking parse(String raw) => switch (raw.trim().toLowerCase()) {
        'off' || 'none' || 'minimal' || '' => off,
        'low' => low,
        'medium' => medium,
        'high' => high,
        _ => off,
      };
}

class AgentModel {
  const AgentModel({
    required this.id,
    required this.chip,
    required this.label,
    required this.provider,
    required this.providerModel,
    this.isDefault = false,
    this.local = false,
    this.supportsThinking = false,
    this.tier = '',
    this.version = '',
    this.usdInPer1m = 0,
    this.usdOutPer1m = 0,
    this.thinking = AgentThinking.off,
  });

  final String id;
  final String chip;
  final String label;
  final String provider;
  final String providerModel;
  final bool isDefault;
  final bool local;
  final bool supportsThinking;
  final String tier;
  final String version;
  final double usdInPer1m;
  final double usdOutPer1m;
  final AgentThinking thinking;

  bool get gemini => provider == 'google';
  bool get canThink {
    if (local) return false;
    if (supportsThinking) return true;
    final s = id.toLowerCase();
    return s == 'auto' || provider == 'alienai' || s.contains('gemini-3') || providerModel.toLowerCase().contains('gemini-3');
  }

  Color get accent => switch (provider) {
        'alienai' => const Color(0xFFF4F4F5),
        'google' => const Color(0xFF38BDF8),
        'ollama' => const Color(0xFF34D399),
        'anthropic' => const Color(0xFFD97706),
        'openai' || 'xai' => const Color(0xFFE4E4E7),
        _ => const Color(0xFFA1A1AA),
      };

  static const alien = AgentModel(id: 'auto', chip: 'Alien AI', label: 'Alien AI', provider: 'alienai', providerModel: 'auto', isDefault: true, supportsThinking: true);
  static const gemini31 = AgentModel(id: 'gemini-3.1-flash-lite', chip: 'Gemini 3.1', label: 'Gemini 3.1 Flash Lite', provider: 'google', providerModel: 'gemini-3.1-flash-lite', supportsThinking: true, usdInPer1m: 75000, usdOutPer1m: 300000);
  static const gpt4o = AgentModel(id: 'gpt-4o', chip: 'GPT-4o', label: 'GPT-4o', provider: 'openai', providerModel: 'gpt-4o');
  static const claude = AgentModel(id: 'claude-sonnet-4-5', chip: 'Claude', label: 'Claude Sonnet 4.5', provider: 'anthropic', providerModel: 'anthropic/claude-sonnet-4-5');
  static const fallback = [alien, gemini31, gpt4o, claude];

  factory AgentModel.fromProto(PromptModelOption m) {
    final slug = m.id == 'alienai' ? 'auto' : m.id;
    final label = m.label.isNotEmpty ? m.label : slug;
    return AgentModel(
      id: slug,
      chip: label.length > 16 ? '${label.substring(0, 13)}…' : label,
      label: label,
      provider: m.provider,
      providerModel: slug == 'auto' ? 'auto' : slug,
      isDefault: m.isDefault,
      supportsThinking: m.supportsThinking,
      usdInPer1m: m.usdInPer1m,
      usdOutPer1m: m.usdOutPer1m,
    );
  }

  factory AgentModel.fromJson(Map<String, dynamic> j) {
    final slug = '${j['slug'] ?? ''}';
    final label = '${j['label'] ?? slug}';
    return AgentModel(
      id: slug,
      chip: label,
      label: label,
      provider: '${j['provider'] ?? ''}',
      providerModel: '${j['provider_model'] ?? slug}',
      isDefault: j['is_default'] == true,
      supportsThinking: j['supports_thinking'] == true,
      tier: '${j['tier'] ?? ''}',
      version: '${j['version'] ?? ''}',
      usdInPer1m: (j['usd_in_per_1m'] as num?)?.toDouble() ?? 0,
      usdOutPer1m: (j['usd_out_per_1m'] as num?)?.toDouble() ?? 0,
    );
  }

  String get priceLabel => agentModelPriceLabel(usdInPer1m, usdOutPer1m);

  AgentModel copyWith({AgentThinking? thinking}) => AgentModel(
        id: id,
        chip: chip,
        label: label,
        provider: provider,
        providerModel: providerModel,
        isDefault: isDefault,
        local: local,
        supportsThinking: supportsThinking,
        tier: tier,
        version: version,
        usdInPer1m: usdInPer1m,
        usdOutPer1m: usdOutPer1m,
        thinking: thinking ?? this.thinking,
      );

  static AgentModel of(String id, [List<AgentModel> models = fallback]) {
    for (final m in models) {
      if (m.id == id) return m;
    }
    return models.isNotEmpty ? models.first : alien;
  }
}

const agentModelRetailMarkup = 1.5;

double agentModelRetailPer1m(double wholesale) => wholesale * agentModelRetailMarkup;

String agentModelPriceLabel(double usdInPer1m, double usdOutPer1m) {
  if (usdInPer1m <= 0 && usdOutPer1m <= 0) return 'Auto';
  final inRetail = agentModelRetailPer1m(usdInPer1m);
  final outRetail = agentModelRetailPer1m(usdOutPer1m);
  final inLabel = usdInPer1m > 0 ? '\$${inRetail.toStringAsFixed(2)}' : '—';
  final outLabel = usdOutPer1m > 0 ? '\$${outRetail.toStringAsFixed(2)}' : '—';
  return '$inLabel / $outLabel per 1M';
}

List<AgentModel> agentModelsFromProto(List<PromptModelOption> rows) =>
    rows.isEmpty ? List<AgentModel>.from(AgentModel.fallback) : [for (final m in rows) AgentModel.fromProto(m)];

List<AgentModel> agentModelFilter(List<AgentModel> models, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return models;
  return models
      .where((o) =>
          o.label.toLowerCase().contains(q) ||
          o.id.toLowerCase().contains(q) ||
          o.provider.toLowerCase().contains(q) ||
          o.tier.toLowerCase().contains(q) ||
          o.version.toLowerCase().contains(q))
      .toList();
}
