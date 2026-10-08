import 'dart:convert';

import 'package:flutter/services.dart';

import 'overlay_effect_presets_data.dart';

enum OverlayEffectParamType { boolean, color, number }

enum OverlayEffectParamGroup { overlay, interaction }

class OverlayEffectParamDef {
  const OverlayEffectParamDef({
    required this.key,
    required this.label,
    required this.type,
    this.group = OverlayEffectParamGroup.overlay,
    this.min,
    this.max,
    this.step,
    this.defaultValue,
  });

  final String key;
  final String label;
  final OverlayEffectParamType type;
  final OverlayEffectParamGroup group;
  final num? min;
  final num? max;
  final num? step;
  final Object? defaultValue;
}

class OverlayEffectPreset {
  const OverlayEffectPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.parameters,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final List<OverlayEffectParamDef> parameters;

  Map<String, Object?> defaultParams() => {for (final p in parameters) p.key: p.defaultValue};

  List<OverlayEffectParamDef> paramsIn(OverlayEffectParamGroup group) =>
      parameters.where((p) => p.group == group).toList();

  bool get hasInteractionParams => parameters.any((p) => p.group == OverlayEffectParamGroup.interaction);
}

class OverlayEffectPresetCatalog {
  OverlayEffectPresetCatalog._(this.presets);

  final List<OverlayEffectPreset> presets;

  static OverlayEffectPresetCatalog? _cached;

  static Future<OverlayEffectPresetCatalog> load() async {
    if (_cached != null) return _cached!;
    final raw = await _loadPresetsJson();
    final list = jsonDecode(raw) as List<dynamic>;
    final presets = list.map((item) => _parsePreset(item as Map<String, dynamic>)).toList();
    _cached = OverlayEffectPresetCatalog._(presets);
    return _cached!;
  }

  static Future<String> _loadPresetsJson() async {
    const keys = [
      'assets/effects/presets.json',
      'packages/alienai/assets/effects/presets.json',
    ];
    for (final key in keys) {
      try {
        return await rootBundle.loadString(key);
      } catch (_) {}
    }
    return kOverlayEffectPresetsJson;
  }

  static String? presetName(String id) => _cached?.presetById(id)?.name;

  OverlayEffectPreset? presetById(String id) {
    for (final preset in presets) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  List<OverlayEffectPreset> filter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return presets;
    return presets
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.id.toLowerCase().contains(q),
        )
        .toList();
  }
}

OverlayEffectPreset _parsePreset(Map<String, dynamic> json) => OverlayEffectPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String? ?? '',
      parameters: (json['parameters'] as List<dynamic>? ?? const [])
          .map((p) => _parseParam(p as Map<String, dynamic>))
          .toList(),
    );

OverlayEffectParamDef _parseParam(Map<String, dynamic> json) => OverlayEffectParamDef(
      key: json['key'] as String,
      label: json['label'] as String,
      group: switch (json['group'] as String? ?? 'overlay') {
        'interaction' => OverlayEffectParamGroup.interaction,
        _ => OverlayEffectParamGroup.overlay,
      },
      type: switch (json['type'] as String) {
        'boolean' => OverlayEffectParamType.boolean,
        'color' => OverlayEffectParamType.color,
        _ => OverlayEffectParamType.number,
      },
      min: json['min'] as num?,
      max: json['max'] as num?,
      step: json['step'] as num?,
      defaultValue: json['default'],
    );
