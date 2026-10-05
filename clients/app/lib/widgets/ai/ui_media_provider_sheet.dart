import 'package:alienai_c35/c/chat/chat_block.dart';
import 'package:alienai_c35/c/generation/media_provider_labels.dart';
import 'package:alienai_c35/c/settings/media_generation_prefs.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/widgets/ai/ui_assistant_provider_icon.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<void> uiMediaProviderSheetShow(
  BuildContext context, {
  required String blockKind,
  required ChatBlock block,
  required Future<void> Function(String provider, {required bool setDefault}) onRegenerate,
}) async {
  final kind = mediaBlockKind(blockKind);
  final current = ChatBlock.mediaProvider(block).isNotEmpty ? ChatBlock.mediaProvider(block) : MediaGenerationPrefs.instance.defaultForKind(kind);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF18181B),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => UiMediaProviderSheet(kind: kind, currentProvider: current, block: block, onRegenerate: onRegenerate),
  );
}

class UiMediaProviderSheet extends StatefulWidget {
  const UiMediaProviderSheet({
    super.key,
    required this.kind,
    required this.currentProvider,
    required this.block,
    required this.onRegenerate,
  });

  final String kind;
  final String currentProvider;
  final ChatBlock block;
  final Future<void> Function(String provider, {required bool setDefault}) onRegenerate;

  @override
  State<UiMediaProviderSheet> createState() => _UiMediaProviderSheetState();
}

class _UiMediaProviderSheetState extends State<UiMediaProviderSheet> {
  late String _selected = widget.currentProvider.trim().isEmpty ? MediaGenerationPrefs.auto : widget.currentProvider;
  var _busy = false;

  List<MediaProviderOption> get _options => mediaProviderOptionsForKind(widget.kind);

  MediaProviderOption get _selectedOpt => _options.firstWhere((o) => o.id == _selected, orElse: () => _options.first);

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = AppStore.instance.wallet;
    final costLabel = mediaEstimatedCostLabel(_selectedOpt.estimatedUsd, billingCurrency: wallet.billingCurrency);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.65),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFF3F3F46), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Text('media.providerSheetTitle'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.w600)),
                if (costLabel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(costLabel, style: const TextStyle(color: Color(0xFF71717A), fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final o = _options[i];
                      final picked = o.id == _selected;
                      return Material(
                        color: picked ? const Color(0xFF27272A) : const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _busy ? null : () => setState(() => _selected = o.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              children: [
                                if (o.iconProvider.isNotEmpty)
                                  UiAssistantProviderIcon(provider: o.iconProvider, size: 20, accent: const Color(0xFF34D399))
                                else
                                  Icon(Icons.auto_awesome_outlined, size: 20, color: Colors.white.withValues(alpha: 0.5)),
                                const SizedBox(width: 12),
                                Expanded(child: Text(o.label, style: TextStyle(color: picked ? const Color(0xFF34D399) : const Color(0xFFE4E4E7), fontSize: 15, fontWeight: picked ? FontWeight.w600 : FontWeight.w500))),
                                if (picked) const Icon(Icons.check_rounded, color: Color(0xFF34D399), size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : () => _run(() => widget.onRegenerate(_selected, setDefault: false)),
                  child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('media.regenerate'.tr()),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(() => widget.onRegenerate(_selected, setDefault: true)),
                  child: Text('media.setDefault'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
