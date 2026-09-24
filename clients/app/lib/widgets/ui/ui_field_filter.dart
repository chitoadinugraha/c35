import 'package:alienai_c35/c/field/field_col.dart';
import 'package:alienai_c35/c/pb/c35/field.pb.dart';
import 'package:alienai_c35/widgets/ui/ui_col_cell.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

class UiFieldFilter extends StatelessWidget {
  const UiFieldFilter({
    super.key,
    required this.fields,
    required this.values,
    required this.onChanged,
    this.host,
  });

  final List<Field> fields;
  final Map<String, String> values;
  final ValueChanged<Map<String, String>> onChanged;
  final UiColCellHost? host;

  void _set(String key, String value) {
    final next = Map<String, String>.from(values);
    if (value.isEmpty) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    onChanged(next);
  }

  Widget _row(BuildContext context, Field field) {
    final col = colFromField(field);
    final value = values[field.key] ?? field.def;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 88,
            child: Text(field.label.isNotEmpty ? field.label : field.key,
                style: const TextStyle(color: _muted, fontSize: 11)),
          ),
          Expanded(
            child: uiColCellBuild(UiColCellScope(
              context: context,
              rowKey: 'filter:${field.key}',
              row: values,
              col: col,
              value: value,
              editable: true,
              onCommit: (v) async => _set(field.key, v),
              host: host,
            )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: fields.map((f) => _row(context, f)).toList(growable: false),
      );
}
