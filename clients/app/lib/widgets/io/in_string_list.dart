import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:flutter/material.dart';

/// Growing list of text fields: one empty row always at the end; empty middle rows collapse.
class InStringList extends StatefulWidget {
  const InStringList({
    super.key,
    required this.values,
    required this.onChanged,
    this.enabled = true,
    this.hintText = 'Add…',
    this.monospace = false,
  });

  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;
  final String hintText;
  final bool monospace;

  @override
  State<InStringList> createState() => _InStringListState();
}

class _InStringListState extends State<InStringList> {
  final _ctrls = <TextEditingController>[];
  var _rows = <String>[''];

  static List<String> _compact(List<String> raw) =>
      raw.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);

  static List<String> _rowsFromValues(List<String> values) {
    final compact = _compact(values);
    return [...compact, ''];
  }

  static bool _sameValues(List<String> a, List<String> b) {
    final ca = _compact(a);
    final cb = _compact(b);
    if (ca.length != cb.length) return false;
    for (var i = 0; i < ca.length; i++) {
      if (ca[i] != cb[i]) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _applyRows(_rowsFromValues(widget.values), notify: false);
  }

  @override
  void didUpdateWidget(covariant InStringList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameValues(oldWidget.values, widget.values)) {
      _applyRows(_rowsFromValues(widget.values), notify: false);
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyRows(List<String> rows, {required bool notify}) {
    _rows = rows.isEmpty ? [''] : rows;
    while (_ctrls.length < _rows.length) {
      _ctrls.add(TextEditingController());
    }
    while (_ctrls.length > _rows.length) {
      _ctrls.removeLast().dispose();
    }
    for (var i = 0; i < _rows.length; i++) {
      if (_ctrls[i].text != _rows[i]) _ctrls[i].text = _rows[i];
    }
    if (notify) setState(() {});
  }

  void _onRowChanged(int index, String text) {
    final next = List<String>.from(_rows);
    next[index] = text;
    final compact = _compact(next);
    final display = [...compact, ''];
    _applyRows(display, notify: true);
    widget.onChanged(compact);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _rows.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < _rows.length - 1 ? 8 : 0),
              child: TextField(
                controller: _ctrls[i],
                enabled: widget.enabled,
                style: TextStyle(
                  color: siteEditorFormText,
                  fontSize: 13,
                  fontFamily: widget.monospace ? 'monospace' : null,
                ),
                decoration: siteEditorInputDecoration(hintText: widget.hintText),
                onChanged: (v) => _onRowChanged(i, v),
              ),
            ),
        ],
      );
}
