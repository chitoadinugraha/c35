import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/pb/c35/inst.pb.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:flutter/material.dart';

Future<void> showInstInfoDialog(BuildContext context, {required AdminApi api, required String instId}) => uiDialogShow(
      context: context,
      builder: (ctx) => _InstInfoDialog(api: api, instId: instId),
    );

class _InstInfoDialog extends StatefulWidget {
  const _InstInfoDialog({required this.api, required this.instId});
  final AdminApi api;
  final String instId;

  @override
  State<_InstInfoDialog> createState() => _InstInfoDialogState();
}

class _InstInfoDialogState extends State<_InstInfoDialog> {
  var _loading = true;
  String? _error;
  InstDoc? _doc;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await widget.api.instGet(widget.instId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _doc = doc;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.75;
    return UiDialog(
      maxWidth: 560,
      padding: uiDialogInsetCompact,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            UiDialogHeader(title: widget.instId, onClose: () => Navigator.pop(context)),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: UILoading(compact: true, message: 'Inst')))
            else if (_error != null)
              Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text(_error!, style: const TextStyle(color: uiDialogMuted, fontSize: 13)))
            else if (_doc != null)
              Flexible(child: _InstInfoBody(doc: _doc!)),
          ],
        ),
      ),
    );
  }
}

class _InstInfoBody extends StatelessWidget {
  const _InstInfoBody({required this.doc});
  final InstDoc doc;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _metaRow('Scope', doc.scope),
            _metaRow('Kind', doc.kind),
            if (doc.topicId.isNotEmpty) _metaRow('Topic', doc.topicId),
            if (doc.topics.isNotEmpty) _metaRow('Topics', doc.topics.join(', ')),
            _metaRow('Priority', '${doc.priority}'),
            _metaRow('Enabled', doc.hasEnabled() && doc.enabled ? 'yes' : 'no'),
            if (doc.phrases.isNotEmpty) _metaRow('Phrases', doc.phrases.join(' · ')),
            if (doc.triggers.isNotEmpty) _metaRow('Triggers', doc.triggers.join(', ')),
            if (doc.includeTools.isNotEmpty) _metaRow('Include tools', doc.includeTools.join(', ')),
            if (doc.excludeTools.isNotEmpty) _metaRow('Exclude tools', doc.excludeTools.join(', ')),
            if (doc.requiresGlobalRoles.isNotEmpty) _metaRow('Roles', doc.requiresGlobalRoles.join(', ')),
            const SizedBox(height: 12),
            const Text('Instruction', style: TextStyle(color: uiDialogMuted, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SelectableText(
              doc.inst.isNotEmpty ? doc.inst : '—',
              style: const TextStyle(color: uiDialogTitleColor, fontSize: 12, height: 1.45),
            ),
          ],
        ),
      );
}

Widget _metaRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: const TextStyle(color: uiDialogMuted, fontSize: 11))),
          Expanded(child: Text(value, style: const TextStyle(color: uiDialogTitleColor, fontSize: 11, height: 1.35))),
        ],
      ),
    );
