import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:flutter/material.dart';

const _text = Color(0xFFF4F4F5);
const _barBg = Color(0xFF27272A);
const _barIn = Color(0xFF60A5FA);
const _barOut = Color(0xFF34D399);

class UiAdminNetworkRow extends StatelessWidget {
  const UiAdminNetworkRow({
    super.key,
    required this.inBps,
    required this.outBps,
    required this.maxBps,
  });

  final double inBps;
  final double outBps;
  final double maxBps;

  double get _scale => maxBps < 1 ? 1 : maxBps;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _bar(label: 'In ${adminFmtBps(inBps)}', value: inBps / _scale, color: _barIn),
            const SizedBox(height: 8),
            _bar(label: 'Out ${adminFmtBps(outBps)}', value: outBps / _scale, color: _barOut),
          ],
        ),
      );

  Widget _bar({required String label, required double value, required Color color}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 8,
              backgroundColor: _barBg,
              color: color,
            ),
          ),
        ],
      );
}
