import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UiCitationChips extends StatelessWidget {
  const UiCitationChips({super.key, required this.citations, this.marginTop = 6});

  final List<Citation> citations;
  final double marginTop;

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) return const SizedBox.shrink();
    final seenHosts = <String>{};
    final uniqueCitations = <Citation>[];
    for (final c in citations) {
      final host = citationHost(c.url);
      if (host.isEmpty || !seenHosts.add(host)) continue;
      uniqueCitations.add(c);
      if (uniqueCitations.length >= 6) break;
    }
    if (uniqueCitations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: marginTop, bottom: 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final c in uniqueCitations) _CitationChip(citation: c),
        ],
      ),
    );
  }
}

class _CitationChip extends StatelessWidget {
  const _CitationChip({required this.citation});

  final Citation citation;

  @override
  Widget build(BuildContext context) {
    final host = citationHost(citation.url);
    final label = host.isNotEmpty ? host : (citation.title.isEmpty ? citation.url : citation.title);
    return Tooltip(
      message: citation.title.isNotEmpty && citation.title != label ? '${citation.title}\n${citation.url}' : citation.url,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: const Color(0xFF1E1E22),
        shape: StadiumBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () async {
            final uri = Uri.tryParse(citation.url);
            if (uri == null) return;
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Image.network(
                    citationFaviconUrl(citation.url),
                    width: 13,
                    height: 13,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.public,
                      size: 13,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 168),
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontSize: 11.5,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
