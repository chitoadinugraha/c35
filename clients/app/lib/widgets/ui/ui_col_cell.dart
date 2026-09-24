import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/io/in_site_contact.dart';
import 'package:alienai_c35/widgets/io/in_site_product.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

typedef UiColCellCommit = Future<void> Function(String value);
typedef UiColCellBuilder = Widget Function(UiColCellScope scope);

final _typeBuilders = <ColType, UiColCellBuilder>{};
final _refBuilders = <String, UiColCellBuilder>{};

void uiColCellRegister(ColType type, UiColCellBuilder builder) => _typeBuilders[type] = builder;

void uiColCellRegisterRef(String refCollection, UiColCellBuilder builder) => _refBuilders[refCollection] = builder;

class UiColCellHost {
  const UiColCellHost({this.siteIid, this.products = const {}, this.contacts = const {}});

  final int? siteIid;
  final Map<String, SiteProduct> products;
  final Map<String, SiteContact> contacts;

  String refLabel(ColDef col, String value) {
    if (value.isEmpty) return '';
    return switch (col.refCollection) {
      'site.product' => products[value]?.name ?? value,
      'site.contact' => contacts[value]?.name ?? value,
      _ => value,
    };
  }
}

class UiColCellScope {
  const UiColCellScope({
    required this.context,
    required this.rowKey,
    required this.row,
    required this.col,
    required this.value,
    required this.editable,
    this.onCommit,
    this.host,
  });

  final BuildContext context;
  final String rowKey;
  final Map<String, String> row;
  final ColDef col;
  final String value;
  final bool editable;
  final UiColCellCommit? onCommit;
  final UiColCellHost? host;
}

var _defaultsReady = false;

void _ensureDefaults() {
  if (_defaultsReady) return;
  _defaultsReady = true;
  _registerDefaults();
}

Widget uiColCellBuild(UiColCellScope scope) {
  _ensureDefaults();
  if (scope.col.type == ColType.COL_TYPE_REF) {
    final ref = scope.col.refCollection;
    if (ref.isNotEmpty) {
      final custom = _refBuilders[ref];
      if (custom != null) return custom(scope);
    }
  }
  final builder = _typeBuilders[scope.col.type] ?? _typeBuilders[ColType.COL_TYPE_TEXT]!;
  return builder(scope);
}

Widget _readText(UiColCellScope scope, String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(text, style: const TextStyle(color: _text, fontSize: 13)),
    );

Widget _textCell(UiColCellScope scope, {bool multiline = false, TextInputType? keyboard}) {
  if (!scope.editable || scope.onCommit == null) return _readText(scope, scope.value);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: _UiColCellTextEdit(
      key: ValueKey('${scope.rowKey}:${scope.col.key}'),
      initial: scope.value,
      multiline: multiline,
      keyboard: keyboard,
      onCommit: scope.onCommit!,
    ),
  );
}

Widget _boolCell(UiColCellScope scope) {
  final on = scope.value.toLowerCase() == 'yes' || scope.value == '1' || scope.value.toLowerCase() == 'true';
  if (!scope.editable || scope.onCommit == null) {
    return _readText(scope, on ? 'yes' : 'no');
  }
  return Center(
    child: Transform.scale(
      scale: 0.72,
      child: Switch.adaptive(
        value: on,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        activeTrackColor: _accent,
        onChanged: (v) => scope.onCommit!(v ? 'yes' : 'no'),
      ),
    ),
  );
}

Widget _picCell(UiColCellScope scope) {
  if (scope.editable && scope.onCommit != null) return _textCell(scope);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: scope.value.isEmpty
        ? const Text('—', style: TextStyle(color: _muted, fontSize: 13))
        : UiImg(src: scope.value, width: 36, height: 36, fallback: const Icon(Icons.image_outlined, size: 20, color: _muted)),
  );
}

Widget _jsonCell(UiColCellScope scope) {
  if (!scope.editable || scope.onCommit == null) {
    final preview = scope.value.replaceAll('\n', ' ');
    final text = preview.length > 80 ? '${preview.substring(0, 80)}…' : preview;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text.isEmpty ? '—' : text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _text, fontSize: 12, fontFamily: 'monospace'),
      ),
    );
  }
  return _textCell(scope, multiline: true);
}

Widget _refCell(UiColCellScope scope) {
  final label = scope.host?.refLabel(scope.col, scope.value) ?? scope.value;
  if (!scope.editable || scope.onCommit == null) {
    return _readText(scope, label.isEmpty ? '—' : label);
  }
  return _textCell(scope);
}

void _registerDefaults() {
  uiColCellRegister(ColType.COL_TYPE_TEXT, _textCell);
  uiColCellRegister(ColType.COL_TYPE_INT, (s) => _textCell(s, keyboard: TextInputType.number));
  uiColCellRegister(ColType.COL_TYPE_MONEY, (s) => _textCell(s, keyboard: TextInputType.number));
  uiColCellRegister(ColType.COL_TYPE_TS, _textCell);
  uiColCellRegister(ColType.COL_TYPE_BOOL, _boolCell);
  uiColCellRegister(ColType.COL_TYPE_PIC, _picCell);
  uiColCellRegister(ColType.COL_TYPE_JSON, _jsonCell);
  uiColCellRegister(ColType.COL_TYPE_REF, _refCell);
  uiColCellRegister(ColType.COL_TYPE_UNSPECIFIED, _textCell);

  uiColCellRegisterRef('site.product', (scope) {
    final host = scope.host;
    if (scope.editable && scope.onCommit != null && host != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: InSiteProduct(
          value: scope.value,
          products: host.products,
          onCommit: scope.onCommit!,
        ),
      );
    }
    final label = host?.refLabel(scope.col, scope.value) ?? scope.value;
    return _readText(scope, label.isEmpty ? '—' : label);
  });

  uiColCellRegisterRef('site.contact', (scope) {
    final host = scope.host;
    if (scope.editable && scope.onCommit != null && host != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: InSiteContact(
          value: scope.value,
          contacts: host.contacts,
          onCommit: scope.onCommit!,
        ),
      );
    }
    final label = host?.refLabel(scope.col, scope.value) ?? scope.value;
    return _readText(scope, label.isEmpty ? '—' : label);
  });
}

class _UiColCellTextEdit extends StatefulWidget {
  const _UiColCellTextEdit({super.key, required this.initial, required this.onCommit, this.multiline = false, this.keyboard});

  final String initial;
  final UiColCellCommit onCommit;
  final bool multiline;
  final TextInputType? keyboard;

  @override
  State<_UiColCellTextEdit> createState() => _UiColCellTextEditState();
}

class _UiColCellTextEditState extends State<_UiColCellTextEdit> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  InputDecoration get _decoration => InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: widget.multiline ? 10 : 8),
        border: const OutlineInputBorder(borderSide: BorderSide(color: _border)),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: _border)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _accent)),
      );

  Future<void> _commit() => widget.onCommit(_ctrl.text.trim());

  @override
  Widget build(BuildContext context) => TextField(
        controller: _ctrl,
        style: TextStyle(color: _text, fontSize: 13, fontFamily: widget.multiline ? 'monospace' : null),
        keyboardType: widget.keyboard,
        minLines: widget.multiline ? 2 : 1,
        maxLines: widget.multiline ? 4 : 1,
        decoration: _decoration,
        onSubmitted: widget.multiline ? null : (_) => _commit(),
        onEditingComplete: _commit,
      );
}
