import 'dart:async';

import 'package:alienai_c35/c/remote/device_prompt_context.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _panel = Color(0xFF18181B);
const _zinc100 = Color(0xFFF4F4F5);
const _zinc400 = Color(0xFFA1A1AA);
const _zinc500 = Color(0xFF71717A);
const _amber = Color(0xFFF59E0B);
const _sky = Color(0xFF38BDF8);

class InDevicePromptComposer extends StatefulWidget {
  const InDevicePromptComposer({
    super.key,
    required this.store,
    required this.deviceName,
    this.dense = false,
  });

  final DevicePromptContextStore store;
  final String deviceName;
  final bool dense;

  @override
  State<InDevicePromptComposer> createState() => _InDevicePromptComposerState();
}

class _InDevicePromptComposerState extends State<InDevicePromptComposer> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _focus = FocusNode();
    widget.store.addListener(_onStore);
  }

  @override
  void didUpdateWidget(covariant InDevicePromptComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      oldWidget.store.removeListener(_onStore);
      widget.store.addListener(_onStore);
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onStore() {
    if (!widget.store.streaming && mounted) setState(() {});
  }

  Future<void> _submit() async {
    var text = _ctrl.text.trim();
    String? turnToolMode;
    if (text.startsWith('/ask ') || text == '/ask') {
      turnToolMode = 'ask';
      text = text.length > 4 ? text.substring(4).trim() : '';
    }
    if (text.isEmpty || !widget.store.sendEnabled) return;
    _ctrl.clear();
    await widget.store.promptSend(text, toolMode: turnToolMode);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final ask = store.toolMode == 'ask';
    final enabled = store.sendEnabled;
    final pad = widget.dense ? 8.0 : 12.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _lockedChip(widget.deviceName),
              const Spacer(),
              if (ask) _modePill(onTap: enabled ? store.toolModeToggle : null),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: widget.dense ? 3 : 4,
                  style: const TextStyle(color: _zinc100, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: enabled ? 'Message Alien AI…' : 'Connect to send',
                    hintStyle: const TextStyle(color: _zinc500, fontSize: 13),
                    filled: true,
                    fillColor: _panel,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                  ),
                  onSubmitted: enabled ? (_) => unawaited(_submit()) : null,
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: enabled ? _amber.withValues(alpha: 0.2) : _panel,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: enabled ? () => unawaited(_submit()) : null,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: store.streaming
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2, color: _amber),
                          )
                        : Icon(Icons.arrow_upward_rounded, size: 20, color: enabled ? _amber : _zinc400),
                  ),
                ),
              ),
            ],
          ),
          if (store.error != null && store.error!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(store.error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _lockedChip(String name) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.devices_rounded, size: 12, color: _amber),
            const SizedBox(width: 4),
            Text('@$name', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _zinc100)),
            const SizedBox(width: 4),
            const Icon(Icons.lock_outline, size: 11, color: _zinc500),
          ],
        ),
      );

  Widget _modePill({VoidCallback? onTap}) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _sky, width: 0.8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 12, color: _sky),
              SizedBox(width: 4),
              Text('Ask', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _sky)),
            ],
          ),
        ),
      );

}
