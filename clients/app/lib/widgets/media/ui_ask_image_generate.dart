import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/media/image_generate_api.dart';
import 'package:alienai_c35/c/media/image_generate_prompt.dart';
import 'package:alienai_c35/c/settings/media_generation_prefs.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:alienai_c35/widgets/ai/ui_assistant_provider_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _dialogW = 420.0;

class GeneratedImage {
  const GeneratedImage({required this.hash, required this.url, required this.prompt});

  final String hash;
  final String url;
  final String prompt;
}

Future<GeneratedImage?> askImageGenerate(
  BuildContext context, {
  required ChatConn conn,
  required ImageGenerateSlot slot,
  required String name,
  String desc = '',
}) =>
    showDialog<GeneratedImage>(
      context: context,
      builder: (ctx) => _AskImageGenerateDialog(conn: conn, slot: slot, name: name, desc: desc),
    );

class _AskImageGenerateDialog extends StatefulWidget {
  const _AskImageGenerateDialog({
    required this.conn,
    required this.slot,
    required this.name,
    required this.desc,
  });

  final ChatConn conn;
  final ImageGenerateSlot slot;
  final String name;
  final String desc;

  @override
  State<_AskImageGenerateDialog> createState() => _AskImageGenerateDialogState();
}

class _AskImageGenerateDialogState extends State<_AskImageGenerateDialog> {
  late final TextEditingController _promptCtrl;
  late String _provider;
  final List<GeneratedImage> _images = [];
  var _selected = -1;
  var _busy = false;
  var _error = '';

  @override
  void initState() {
    super.initState();
    _promptCtrl = TextEditingController(
      text: imageGenerateDefaultPrompt(slot: widget.slot, name: widget.name, desc: widget.desc),
    );
    _provider = _sessionProvider(MediaGenerationPrefs.instance.image);
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  static String _sessionProvider(String stored) {
    final v = stored.trim().toLowerCase();
    return MediaGenerationPrefs.imageProviders.contains(v) ? v : MediaGenerationPrefs.auto;
  }

  bool get _promptEmpty => _promptCtrl.text.trim().isEmpty;

  static const _providerChoices = <(String value, String label)>[
    (MediaGenerationPrefs.auto, 'Auto'),
    (MediaGenerationPrefs.gemini, 'Gemini'),
    (MediaGenerationPrefs.grok, 'Grok'),
  ];

  Widget _providerRow(String value, String label) {
    final Widget icon = switch (value) {
      MediaGenerationPrefs.auto => const UiAlienIcon(size: 18, color: _text),
      MediaGenerationPrefs.gemini => const UiAssistantProviderIcon(provider: 'google', size: 18),
      MediaGenerationPrefs.grok => const UiAssistantProviderIcon(provider: 'xai', size: 18),
      _ => const SizedBox(width: 18, height: 18),
    };
    return Row(
      children: [
        icon,
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: _text, fontSize: 13)),
      ],
    );
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        labelStyle: const TextStyle(color: _muted, fontSize: 12),
        border: const OutlineInputBorder(borderSide: BorderSide(color: _border)),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: _border)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _accent)),
      );

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final result = await imageGenerate(widget.conn, prompt: prompt, provider: _provider);
      if (!mounted) return;
      if (result.hash.trim().isEmpty) {
        setState(() {
          _busy = false;
          _error = uiFriendlyError(Exception('Image generation failed'));
        });
        return;
      }
      setState(() {
        _busy = false;
        _images.add(GeneratedImage(hash: result.hash, url: result.url, prompt: prompt));
        _selected = _images.length - 1;
      });
    } on ImageGenerateQuotaException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = uiFriendlyError(e);
      });
    }
  }

  void _use() {
    if (_selected < 0 || _selected >= _images.length) return;
    Navigator.pop(context, _images[_selected]);
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = _images.isNotEmpty;
    final canGenerate = !_promptEmpty && !_busy;

    return AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      scrollable: true,
      title: const Text('Generate image', style: TextStyle(color: _text, fontSize: 16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SizedBox(
        width: _dialogW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey('ask_image_provider_$_provider'),
              initialValue: _provider,
              isExpanded: true,
              dropdownColor: const Color(0xFF27272A),
              style: const TextStyle(color: _text, fontSize: 13),
              decoration: _fieldDecoration('Provider'),
              selectedItemBuilder: (context) => [
                for (final (value, label) in _providerChoices) Align(alignment: Alignment.centerLeft, child: _providerRow(value, label)),
              ],
              items: [
                for (final (value, label) in _providerChoices)
                  DropdownMenuItem(value: value, child: _providerRow(value, label)),
              ],
              onChanged: _busy
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _provider = v);
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptCtrl,
              minLines: 4,
              maxLines: 8,
              style: const TextStyle(color: _text, fontSize: 13),
              decoration: _fieldDecoration('Prompt'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            const Text(
              'This uses your frontier API quota.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error, style: const TextStyle(color: Color(0xFFF87171), fontSize: 13)),
            ],
            if (hasImages) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final selected = i == _selected;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = i),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selected ? _accent : _border, width: selected ? 2 : 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: UiImg(
                            src: _images[i].url,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            fallback: const ColoredBox(
                              color: Color(0xFF3F3F46),
                              child: SizedBox(width: 72, height: 72),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canGenerate ? _generate : null,
          style: FilledButton.styleFrom(
            backgroundColor: hasImages ? const Color(0xFF3F3F46) : _accent,
            foregroundColor: hasImages ? _text : Colors.black,
            disabledBackgroundColor: const Color(0xFF27272A),
            disabledForegroundColor: _muted,
          ),
          child: _busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: hasImages ? _text : Colors.black),
                )
              : Text(hasImages ? 'Regenerate' : 'Generate'),
        ),
        if (hasImages)
          FilledButton(
            onPressed: _selected < 0 ? null : _use,
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
            child: const Text('Use image'),
          ),
      ],
    );
  }
}
