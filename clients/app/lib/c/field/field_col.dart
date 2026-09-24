import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/field.pb.dart';

ColType colTypeFromFieldType(FieldType type) => switch (type) {
      FieldType.FIELD_TYPE_TEXT => ColType.COL_TYPE_TEXT,
      FieldType.FIELD_TYPE_INT => ColType.COL_TYPE_INT,
      FieldType.FIELD_TYPE_MONEY => ColType.COL_TYPE_MONEY,
      FieldType.FIELD_TYPE_BOOL => ColType.COL_TYPE_BOOL,
      FieldType.FIELD_TYPE_PIC => ColType.COL_TYPE_PIC,
      FieldType.FIELD_TYPE_JSON => ColType.COL_TYPE_JSON,
      FieldType.FIELD_TYPE_REF => ColType.COL_TYPE_REF,
      FieldType.FIELD_TYPE_TS => ColType.COL_TYPE_TS,
      _ => ColType.COL_TYPE_UNSPECIFIED,
    };

FieldType fieldTypeFromColType(ColType type) => switch (type) {
      ColType.COL_TYPE_TEXT => FieldType.FIELD_TYPE_TEXT,
      ColType.COL_TYPE_INT => FieldType.FIELD_TYPE_INT,
      ColType.COL_TYPE_MONEY => FieldType.FIELD_TYPE_MONEY,
      ColType.COL_TYPE_BOOL => FieldType.FIELD_TYPE_BOOL,
      ColType.COL_TYPE_PIC => FieldType.FIELD_TYPE_PIC,
      ColType.COL_TYPE_JSON => FieldType.FIELD_TYPE_JSON,
      ColType.COL_TYPE_REF => FieldType.FIELD_TYPE_REF,
      ColType.COL_TYPE_TS => FieldType.FIELD_TYPE_TS,
      _ => FieldType.FIELD_TYPE_UNSPECIFIED,
    };

Field fieldFromColDef(ColDef col) => Field(
      key: col.key,
      label: col.label,
      type: col.hasType() ? fieldTypeFromColType(col.type) : FieldType.FIELD_TYPE_TEXT,
      refCollection: col.refCollection,
    );

ColDef colFromField(Field field) => ColDef(
      key: field.key,
      label: field.label,
      type: field.hasType() ? colTypeFromFieldType(field.type) : ColType.COL_TYPE_TEXT,
      refCollection: field.refCollection,
    );
