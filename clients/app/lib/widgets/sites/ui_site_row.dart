import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _selectedBg = Color(0xFF18181B);
const _accent = Color(0xFF34D399);

class UiSiteRow extends StatelessWidget {
  const UiSiteRow({
    super.key,
    required this.row,
    required this.selected,
    required this.onTap,
  });

  final SiteRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? _selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF27272A),
                  child: row.pic.isNotEmpty
                      ? ClipOval(child: Image.network(row.pic, width: 32, height: 32, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _icon()))
                      : _icon(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (row.isPinned) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.push_pin, size: 12, color: _muted)),
                          Expanded(
                            child: Text(row.name.isNotEmpty ? row.name : row.alienId, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(row.alienId.isNotEmpty ? row.alienId : '${row.siteIid}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                ),
                if (row.publishedVersionId.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                    child: const Text('live', style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _icon() => const Icon(Icons.language_outlined, size: 16, color: _muted);
}
