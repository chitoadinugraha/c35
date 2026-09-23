import 'package:alienai_c35/c/pb/c35/collection.pb.dart';

ColDef _col(String key, String label, ColType type, {bool readonly = false, bool required = false, bool inlineEditable = true}) =>
    ColDef(key: key, label: label, type: type, readonly: readonly, required: required, inlineEditable: inlineEditable);

TableDef _productTable() => TableDef(
      collection: 'site.product',
      label: 'Products',
      syncName: 'site_product',
      siteScoped: true,
      primaryKey: 'site_iid,product_id',
      columns: [
        _col('product_id', 'ID', ColType.COL_TYPE_INT, readonly: true, required: true),
        _col('name', 'Name', ColType.COL_TYPE_TEXT, required: true),
        _col('desc', 'Description', ColType.COL_TYPE_TEXT),
        _col('sku', 'SKU', ColType.COL_TYPE_TEXT),
        _col('unit', 'Unit', ColType.COL_TYPE_TEXT),
        _col('price', 'Price', ColType.COL_TYPE_MONEY),
        _col('pic', 'Image', ColType.COL_TYPE_PIC),
        _col('category', 'Category', ColType.COL_TYPE_TEXT),
        _col('stock_qty', 'Stock', ColType.COL_TYPE_INT),
        _col('can_sell', 'Sell', ColType.COL_TYPE_BOOL),
        _col('can_reserve', 'Reserve', ColType.COL_TYPE_BOOL),
        _col('track_stock', 'Track stock', ColType.COL_TYPE_BOOL),
        _col('is_archived', 'Archived', ColType.COL_TYPE_BOOL),
        _col('product_json', 'Extra', ColType.COL_TYPE_JSON),
        _col('updated_ts_ms', 'Updated', ColType.COL_TYPE_TS, readonly: true, inlineEditable: false),
      ],
      subtables: [
        SubTableDef(
          collection: 'site.product_embed',
          label: 'Alt labels',
          fkKeys: ['site_iid', 'product_id'],
          syncName: 'site_product_embed',
        ),
      ],
    );

TableDef _contactTable() => TableDef(
      collection: 'site.contact',
      label: 'Contacts',
      syncName: 'site_contact',
      siteScoped: true,
      primaryKey: 'site_iid,contact_id',
      columns: [
        _col('contact_id', 'ID', ColType.COL_TYPE_INT, readonly: true, required: true),
        _col('name', 'Name', ColType.COL_TYPE_TEXT, required: true),
        _col('phone', 'Phone', ColType.COL_TYPE_TEXT),
        _col('email', 'Email', ColType.COL_TYPE_TEXT),
        _col('address', 'Address', ColType.COL_TYPE_TEXT),
        _col('note', 'Note', ColType.COL_TYPE_TEXT),
        _col('meta_json', 'Meta', ColType.COL_TYPE_JSON),
        _col('is_archived', 'Archived', ColType.COL_TYPE_BOOL),
        _col('updated_ts_ms', 'Updated', ColType.COL_TYPE_TS, readonly: true, inlineEditable: false),
      ],
    );

TableDef _objectTable() => TableDef(
      collection: 'site.object',
      label: 'Objects',
      syncName: 'site_object',
      siteScoped: true,
      primaryKey: 'site_iid,id',
      columns: [
        _col('id', 'ID', ColType.COL_TYPE_INT, readonly: true, required: true),
        _col('client_id', 'Client ID', ColType.COL_TYPE_TEXT),
        _col('name', 'Name', ColType.COL_TYPE_TEXT, required: true),
        _col('code', 'Code', ColType.COL_TYPE_TEXT),
        _col('kind', 'Kind', ColType.COL_TYPE_TEXT),
        ColDef(key: 'product_id', label: 'Product', type: ColType.COL_TYPE_REF, refCollection: 'site.product'),
        _col('can_order', 'Order', ColType.COL_TYPE_BOOL),
        _col('can_be_reserved', 'Reserve', ColType.COL_TYPE_BOOL),
        _col('is_active', 'Active', ColType.COL_TYPE_BOOL),
        _col('desc', 'Description', ColType.COL_TYPE_TEXT),
        _col('pic', 'Image', ColType.COL_TYPE_PIC),
        _col('meta_json', 'Meta', ColType.COL_TYPE_JSON),
        _col('updated_ts_ms', 'Updated', ColType.COL_TYPE_TS, readonly: true, inlineEditable: false),
      ],
    );

TableDef _domainTable() => TableDef(
      collection: 'site.domain',
      label: 'Domains',
      syncName: 'site_domain',
      siteScoped: true,
      primaryKey: 'site_iid,id',
      columns: [
        _col('id', 'ID', ColType.COL_TYPE_INT, readonly: true, required: true),
        _col('hostname', 'Hostname', ColType.COL_TYPE_TEXT, required: true),
        _col('is_primary', 'Primary', ColType.COL_TYPE_BOOL),
        _col('tls_status', 'TLS', ColType.COL_TYPE_TEXT, readonly: true, inlineEditable: false),
        _col('verified_ts_ms', 'Verified', ColType.COL_TYPE_TS, readonly: true, inlineEditable: false),
        _col('updated_ts_ms', 'Updated', ColType.COL_TYPE_TS, readonly: true, inlineEditable: false),
      ],
    );

TableDef _productEmbedTable() => TableDef(
      collection: 'site.product_embed',
      label: 'Alt labels',
      syncName: 'site_product_embed',
      siteScoped: true,
      primaryKey: 'site_iid,embed_id',
      columns: [
        _col('embed_id', 'ID', ColType.COL_TYPE_INT, readonly: true, required: true),
        _col('product_id', 'Product', ColType.COL_TYPE_INT, readonly: true, required: true),
        _col('label', 'Label', ColType.COL_TYPE_TEXT, required: true),
        _col('updated_ts_ms', 'Updated', ColType.COL_TYPE_TS, readonly: true, inlineEditable: false),
      ],
    );

List<TableDef> collectionDefListFallback() => [_productTable(), _contactTable(), _objectTable(), _domainTable()];

TableDef? collectionDefEmbedFallback() => _productEmbedTable();

TableDef? collectionDefForFallback(String collection) =>
    collectionDefListFallback().where((t) => t.collection == collection).firstOrNull ?? (collection == 'site.product_embed' ? _productEmbedTable() : null);
