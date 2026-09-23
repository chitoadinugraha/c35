import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/c/pb/c35/stats.pb.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _barBg = Color(0xFF27272A);
const _barFill = Color(0xFF34D399);
const _barWarn = Color(0xFFFBBF24);
const _barCrit = Color(0xFFF87171);

class UiAdminVolumeRow extends StatelessWidget {
  const UiAdminVolumeRow({super.key, required this.volume, this.showNode = false});

  final VolumeStat volume;
  final bool showNode;

  Color get _fill {
    final pct = adminPct(volume.usedBytes, volume.capacityBytes);
    if (pct >= 90) return _barCrit;
    if (pct >= 80) return _barWarn;
    return _barFill;
  }

  String get _label {
    var label = volume.label.isNotEmpty ? volume.label : volume.pvcName;
    if (showNode && volume.nodeName.isNotEmpty) label = '$label @ ${volume.nodeName}';
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final pct = adminPct(volume.usedBytes, volume.capacityBytes);
    final detail = '${adminFmtBytes(volume.usedBytes)} / ${adminFmtBytes(volume.capacityBytes)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(_label, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w500))),
              Text(detail, style: const TextStyle(color: _muted, fontSize: 12)),
              if (pct >= 80) ...[
                const SizedBox(width: 6),
                Icon(pct >= 90 ? Icons.error_outline : Icons.warning_amber_rounded, size: 14, color: _fill),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: _barBg,
              color: _fill,
            ),
          ),
        ],
      ),
    );
  }
}
