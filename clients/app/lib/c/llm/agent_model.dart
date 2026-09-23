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

  static const alien = AgentModel(id: 'auto', chip: 'Alien AI', label: 'Alien AI', provider: 'alienai', providerModel: 'auto', isDefault: true, supportsThinking: true, usdInPer1m: 0.075, usdOutPer1m: 0.3);
  static const gemini31 = AgentModel(id: 'gemini-3.1-flash-lite', chip: 'Gemini 3.1', label: 'Gemini 3.1 Flash Lite', provider: 'google', providerModel: 'gemini-3.1-flash-lite', supportsThinking: true, usdInPer1m: 75000, usdOutPer1m: 300000);
  static const gpt4o = AgentModel(id: 'gpt-4o', chip: 'GPT-4o', label: 'GPT-4o', provider: 'openai', providerModel: 'gpt-4o');
  static const claude = AgentModel(id: 'claude-sonnet-4-5', chip: 'Claude', label: 'Claude Sonnet 4.5', provider: 'anthropic', providerModel: 'anthropic/claude-sonnet-4-5');
  static const fallback = [alien];

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

bool agentModelChatEligible(AgentModel m) {
  if (m.provider != 'google') return true;
  final s = m.id.toLowerCase();
  const skip = ['transcribe', 'computer-use', 'robotics', 'deep-research', 'lyria', 'nano-banana', 'omni', 'customtools'];
  if (skip.any(s.contains)) return false;
  if (s.contains('latest')) return s.contains('flash') || s.contains('pro');
  return s.contains('flash') || s.contains('pro');
}

List<AgentModel> agentModelsFromProto(List<PromptModelOption> rows) {
  if (rows.isEmpty) return const [AgentModel.alien];
  final out = rows.map(AgentModel.fromProto).where(agentModelChatEligible).toList()..sort(agentModelSort);
  return out.isEmpty ? const [AgentModel.alien] : out;
}

int agentModelProviderBand(String provider) => switch (provider) {
      'alienai' => 0,
      'google' => 100,
      'openai' => 200,
      'anthropic' => 300,
      'deepseek' => 400,
      _ => 900,
    };

int agentModelFamilyPriority(AgentModel m) {
  final s = '${m.id} ${m.label}'.toLowerCase();
  if (s.contains('flash-lite') || s.contains('flash_lite')) return 0;
  if (s.contains('flash')) return 10;
  if (s.contains('pro')) return 20;
  return 90;
}

int agentModelVersionRank(AgentModel m) {
  final nums = RegExp(r'\d+').allMatches('${m.id} ${m.label}').map((m) => int.tryParse(m.group(0) ?? '') ?? 0).toList();
  if (nums.isEmpty) return 0;
  final major = nums[0];
  final minor = nums.length > 1 ? nums[1] : 0;
  final patch = nums.length > 2 ? nums[2] : 0;
  return major * 1000000 + minor * 1000 + patch;
}

int agentModelSort(AgentModel a, AgentModel b) {
  final band = agentModelProviderBand(a.provider).compareTo(agentModelProviderBand(b.provider));
  if (band != 0) return band;
  final fam = agentModelFamilyPriority(a).compareTo(agentModelFamilyPriority(b));
  if (fam != 0) return fam;
  final ver = agentModelVersionRank(b).compareTo(agentModelVersionRank(a));
  if (ver != 0) return ver;
  return a.label.compareTo(b.label);
}

String agentModelProviderLabel(String provider) => switch (provider) {
      '' => 'All Providers',
      'alienai' => 'Alien AI',
      'google' => 'Gemini',
      'openai' => 'ChatGPT',
      'anthropic' => 'Claude',
      'deepseek' => 'Deepseek',
      _ => provider,
    };

const _agentModelProviderOrder = ['alienai', 'google', 'openai', 'anthropic', 'deepseek'];

List<String> agentModelProviders(List<AgentModel> models) {
  final seen = <String>{};
  final out = <String>[''];
  for (final m in models) {
    if (seen.add(m.provider)) out.add(m.provider);
  }
  out.sort((a, b) {
    if (a.isEmpty) return -1;
    if (b.isEmpty) return 1;
    final ai = _agentModelProviderOrder.indexOf(a);
    final bi = _agentModelProviderOrder.indexOf(b);
    if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
    if (ai >= 0) return -1;
    if (bi >= 0) return 1;
    return a.compareTo(b);
  });
  return out;
}

List<AgentModel> agentModelFilter(List<AgentModel> models, String query, {String provider = ''}) {
  final q = query.trim().toLowerCase();
  final p = provider.trim();
  return models.where((o) {
    if (p.isNotEmpty && o.provider != p) return false;
    if (q.isEmpty) return true;
    return o.label.toLowerCase().contains(q) ||
        o.id.toLowerCase().contains(q) ||
        o.provider.toLowerCase().contains(q) ||
        agentModelProviderLabel(o.provider).toLowerCase().contains(q) ||
        o.tier.toLowerCase().contains(q) ||
        o.version.toLowerCase().contains(q);
  }).toList();
}
