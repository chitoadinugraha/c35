// This is a generated file - do not edit.
//
// Generated from c35/consumption.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use consumeMealTypeDescriptor instead')
const ConsumeMealType$json = {
  '1': 'ConsumeMealType',
  '2': [
    {'1': 'CONSUME_MEAL_TYPE_OTHER', '2': 0},
    {'1': 'CONSUME_MEAL_TYPE_BREAKFAST', '2': 1},
    {'1': 'CONSUME_MEAL_TYPE_LUNCH', '2': 2},
    {'1': 'CONSUME_MEAL_TYPE_DINNER', '2': 3},
    {'1': 'CONSUME_MEAL_TYPE_SNACK', '2': 4},
    {'1': 'CONSUME_MEAL_TYPE_DESSERT', '2': 5},
    {'1': 'CONSUME_MEAL_TYPE_LATE_NIGHT', '2': 6},
  ],
};

/// Descriptor for `ConsumeMealType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List consumeMealTypeDescriptor = $convert.base64Decode(
    'Cg9Db25zdW1lTWVhbFR5cGUSGwoXQ09OU1VNRV9NRUFMX1RZUEVfT1RIRVIQABIfChtDT05TVU'
    '1FX01FQUxfVFlQRV9CUkVBS0ZBU1QQARIbChdDT05TVU1FX01FQUxfVFlQRV9MVU5DSBACEhwK'
    'GENPTlNVTUVfTUVBTF9UWVBFX0RJTk5FUhADEhsKF0NPTlNVTUVfTUVBTF9UWVBFX1NOQUNLEA'
    'QSHQoZQ09OU1VNRV9NRUFMX1RZUEVfREVTU0VSVBAFEiAKHENPTlNVTUVfTUVBTF9UWVBFX0xB'
    'VEVfTklHSFQQBg==');

@$core.Deprecated('Use nutritionDescriptor instead')
const Nutrition$json = {
  '1': 'Nutrition',
  '2': [
    {'1': 'calories', '3': 1, '4': 1, '5': 5, '10': 'calories'},
    {'1': 'protein', '3': 2, '4': 1, '5': 5, '10': 'protein'},
    {'1': 'fat', '3': 3, '4': 1, '5': 5, '10': 'fat'},
    {'1': 'carbs', '3': 4, '4': 1, '5': 5, '10': 'carbs'},
    {'1': 'fiber', '3': 5, '4': 1, '5': 5, '10': 'fiber'},
    {'1': 'sugar', '3': 6, '4': 1, '5': 5, '10': 'sugar'},
    {'1': 'sodium', '3': 7, '4': 1, '5': 5, '10': 'sodium'},
    {'1': 'potassium', '3': 8, '4': 1, '5': 5, '10': 'potassium'},
    {'1': 'vitamin_a', '3': 9, '4': 1, '5': 5, '10': 'vitaminA'},
    {'1': 'vitamin_c', '3': 10, '4': 1, '5': 5, '10': 'vitaminC'},
    {'1': 'vitamin_d', '3': 11, '4': 1, '5': 5, '10': 'vitaminD'},
    {'1': 'vitamin_e', '3': 12, '4': 1, '5': 5, '10': 'vitaminE'},
    {'1': 'vitamin_k', '3': 13, '4': 1, '5': 5, '10': 'vitaminK'},
    {'1': 'calcium', '3': 14, '4': 1, '5': 5, '10': 'calcium'},
    {'1': 'iron', '3': 15, '4': 1, '5': 5, '10': 'iron'},
    {'1': 'magnesium', '3': 16, '4': 1, '5': 5, '10': 'magnesium'},
    {'1': 'phosphorus', '3': 17, '4': 1, '5': 5, '10': 'phosphorus'},
    {'1': 'zinc', '3': 18, '4': 1, '5': 5, '10': 'zinc'},
    {'1': 'copper', '3': 19, '4': 1, '5': 5, '10': 'copper'},
  ],
};

/// Descriptor for `Nutrition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nutritionDescriptor = $convert.base64Decode(
    'CglOdXRyaXRpb24SGgoIY2Fsb3JpZXMYASABKAVSCGNhbG9yaWVzEhgKB3Byb3RlaW4YAiABKA'
    'VSB3Byb3RlaW4SEAoDZmF0GAMgASgFUgNmYXQSFAoFY2FyYnMYBCABKAVSBWNhcmJzEhQKBWZp'
    'YmVyGAUgASgFUgVmaWJlchIUCgVzdWdhchgGIAEoBVIFc3VnYXISFgoGc29kaXVtGAcgASgFUg'
    'Zzb2RpdW0SHAoJcG90YXNzaXVtGAggASgFUglwb3Rhc3NpdW0SGwoJdml0YW1pbl9hGAkgASgF'
    'Ugh2aXRhbWluQRIbCgl2aXRhbWluX2MYCiABKAVSCHZpdGFtaW5DEhsKCXZpdGFtaW5fZBgLIA'
    'EoBVIIdml0YW1pbkQSGwoJdml0YW1pbl9lGAwgASgFUgh2aXRhbWluRRIbCgl2aXRhbWluX2sY'
    'DSABKAVSCHZpdGFtaW5LEhgKB2NhbGNpdW0YDiABKAVSB2NhbGNpdW0SEgoEaXJvbhgPIAEoBV'
    'IEaXJvbhIcCgltYWduZXNpdW0YECABKAVSCW1hZ25lc2l1bRIeCgpwaG9zcGhvcnVzGBEgASgF'
    'UgpwaG9zcGhvcnVzEhIKBHppbmMYEiABKAVSBHppbmMSFgoGY29wcGVyGBMgASgFUgZjb3BwZX'
    'I=');

@$core.Deprecated('Use consumptionItemDescriptor instead')
const ConsumptionItem$json = {
  '1': 'ConsumptionItem',
  '2': [
    {'1': 'idx', '3': 1, '4': 1, '5': 5, '10': 'idx'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'name_id', '3': 3, '4': 1, '5': 9, '10': 'nameId'},
    {'1': 'qty', '3': 4, '4': 1, '5': 2, '10': 'qty'},
    {'1': 'pic', '3': 5, '4': 1, '5': 9, '10': 'pic'},
    {
      '1': 'nutrition',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.c35.Nutrition',
      '10': 'nutrition'
    },
  ],
};

/// Descriptor for `ConsumptionItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List consumptionItemDescriptor = $convert.base64Decode(
    'Cg9Db25zdW1wdGlvbkl0ZW0SEAoDaWR4GAEgASgFUgNpZHgSEgoEbmFtZRgCIAEoCVIEbmFtZR'
    'IXCgduYW1lX2lkGAMgASgJUgZuYW1lSWQSEAoDcXR5GAQgASgCUgNxdHkSEAoDcGljGAUgASgJ'
    'UgNwaWMSLAoJbnV0cml0aW9uGAYgASgLMg4uYzM1Lk51dHJpdGlvblIJbnV0cml0aW9u');

@$core.Deprecated('Use consumptionDescriptor instead')
const Consumption$json = {
  '1': 'Consumption',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'note', '3': 3, '4': 1, '5': 9, '10': 'note'},
    {'1': 'photo_hash', '3': 4, '4': 1, '5': 9, '10': 'photoHash'},
    {'1': 'meal_fingerprint', '3': 5, '4': 1, '5': 9, '10': 'mealFingerprint'},
    {
      '1': 'meal_type',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.c35.ConsumeMealType',
      '10': 'mealType'
    },
    {'1': 'pics', '3': 7, '4': 3, '5': 9, '10': 'pics'},
    {'1': 'logged_ts_ms', '3': 8, '4': 1, '5': 3, '10': 'loggedTsMs'},
    {'1': 'is_archived', '3': 9, '4': 1, '5': 8, '10': 'isArchived'},
    {
      '1': 'items',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.c35.ConsumptionItem',
      '10': 'items'
    },
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `Consumption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List consumptionDescriptor = $convert.base64Decode(
    'CgtDb25zdW1wdGlvbhIOCgJpZBgBIAEoA1ICaWQSGwoJb3duZXJfaWlkGAIgASgDUghvd25lck'
    'lpZBISCgRub3RlGAMgASgJUgRub3RlEh0KCnBob3RvX2hhc2gYBCABKAlSCXBob3RvSGFzaBIp'
    'ChBtZWFsX2ZpbmdlcnByaW50GAUgASgJUg9tZWFsRmluZ2VycHJpbnQSMQoJbWVhbF90eXBlGA'
    'YgASgOMhQuYzM1LkNvbnN1bWVNZWFsVHlwZVIIbWVhbFR5cGUSEgoEcGljcxgHIAMoCVIEcGlj'
    'cxIgCgxsb2dnZWRfdHNfbXMYCCABKANSCmxvZ2dlZFRzTXMSHwoLaXNfYXJjaGl2ZWQYCSABKA'
    'hSCmlzQXJjaGl2ZWQSKgoFaXRlbXMYCiADKAsyFC5jMzUuQ29uc3VtcHRpb25JdGVtUgVpdGVt'
    'cxIiCg1jcmVhdGVkX3RzX21zGBQgASgDUgtjcmVhdGVkVHNNcxIiCg11cGRhdGVkX3RzX21zGB'
    'UgASgDUgt1cGRhdGVkVHNNcxIiCg1kZWxldGVkX3RzX21zGBYgASgDUgtkZWxldGVkVHNNcw==');

@$core.Deprecated('Use consumptionWaterDescriptor instead')
const ConsumptionWater$json = {
  '1': 'ConsumptionWater',
  '2': [
    {'1': 'owner_iid', '3': 1, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'day_id', '3': 2, '4': 1, '5': 9, '10': 'dayId'},
    {'1': 'ml', '3': 3, '4': 1, '5': 5, '10': 'ml'},
    {'1': 'goal_ml', '3': 4, '4': 1, '5': 5, '10': 'goalMl'},
    {'1': 'entry_count', '3': 5, '4': 1, '5': 5, '10': 'entryCount'},
    {'1': 'created_ts_ms', '3': 10, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 11, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 12, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `ConsumptionWater`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List consumptionWaterDescriptor = $convert.base64Decode(
    'ChBDb25zdW1wdGlvbldhdGVyEhsKCW93bmVyX2lpZBgBIAEoA1IIb3duZXJJaWQSFQoGZGF5X2'
    'lkGAIgASgJUgVkYXlJZBIOCgJtbBgDIAEoBVICbWwSFwoHZ29hbF9tbBgEIAEoBVIGZ29hbE1s'
    'Eh8KC2VudHJ5X2NvdW50GAUgASgFUgplbnRyeUNvdW50EiIKDWNyZWF0ZWRfdHNfbXMYCiABKA'
    'NSC2NyZWF0ZWRUc01zEiIKDXVwZGF0ZWRfdHNfbXMYCyABKANSC3VwZGF0ZWRUc01zEiIKDWRl'
    'bGV0ZWRfdHNfbXMYDCABKANSC2RlbGV0ZWRUc01z');

@$core.Deprecated('Use consumptionPrefsDescriptor instead')
const ConsumptionPrefs$json = {
  '1': 'ConsumptionPrefs',
  '2': [
    {'1': 'owner_iid', '3': 1, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'calorie_goal_kcal', '3': 2, '4': 1, '5': 5, '10': 'calorieGoalKcal'},
    {'1': 'water_goal_ml', '3': 3, '4': 1, '5': 5, '10': 'waterGoalMl'},
    {'1': 'updated_ts_ms', '3': 4, '4': 1, '5': 3, '10': 'updatedTsMs'},
  ],
};

/// Descriptor for `ConsumptionPrefs`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List consumptionPrefsDescriptor = $convert.base64Decode(
    'ChBDb25zdW1wdGlvblByZWZzEhsKCW93bmVyX2lpZBgBIAEoA1IIb3duZXJJaWQSKgoRY2Fsb3'
    'JpZV9nb2FsX2tjYWwYAiABKAVSD2NhbG9yaWVHb2FsS2NhbBIiCg13YXRlcl9nb2FsX21sGAMg'
    'ASgFUgt3YXRlckdvYWxNbBIiCg11cGRhdGVkX3RzX21zGAQgASgDUgt1cGRhdGVkVHNNcw==');

@$core.Deprecated('Use reqConsumptionListDescriptor instead')
const ReqConsumptionList$json = {
  '1': 'ReqConsumptionList',
  '2': [
    {'1': 'day_id', '3': 1, '4': 1, '5': 9, '10': 'dayId'},
    {'1': 'after_id', '3': 2, '4': 1, '5': 3, '10': 'afterId'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqConsumptionList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqConsumptionListDescriptor = $convert.base64Decode(
    'ChJSZXFDb25zdW1wdGlvbkxpc3QSFQoGZGF5X2lkGAEgASgJUgVkYXlJZBIZCghhZnRlcl9pZB'
    'gCIAEoA1IHYWZ0ZXJJZBIUCgVsaW1pdBgDIAEoBVIFbGltaXQ=');

@$core.Deprecated('Use resConsumptionListDescriptor instead')
const ResConsumptionList$json = {
  '1': 'ResConsumptionList',
  '2': [
    {
      '1': 'consumptions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.Consumption',
      '10': 'consumptions'
    },
  ],
};

/// Descriptor for `ResConsumptionList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resConsumptionListDescriptor = $convert.base64Decode(
    'ChJSZXNDb25zdW1wdGlvbkxpc3QSNAoMY29uc3VtcHRpb25zGAEgAygLMhAuYzM1LkNvbnN1bX'
    'B0aW9uUgxjb25zdW1wdGlvbnM=');

@$core.Deprecated('Use reqConsumptionPutDescriptor instead')
const ReqConsumptionPut$json = {
  '1': 'ReqConsumptionPut',
  '2': [
    {
      '1': 'consumption',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.Consumption',
      '10': 'consumption'
    },
  ],
};

/// Descriptor for `ReqConsumptionPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqConsumptionPutDescriptor = $convert.base64Decode(
    'ChFSZXFDb25zdW1wdGlvblB1dBIyCgtjb25zdW1wdGlvbhgBIAEoCzIQLmMzNS5Db25zdW1wdG'
    'lvblILY29uc3VtcHRpb24=');

@$core.Deprecated('Use resConsumptionPutDescriptor instead')
const ResConsumptionPut$json = {
  '1': 'ResConsumptionPut',
  '2': [
    {
      '1': 'consumption',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.Consumption',
      '10': 'consumption'
    },
    {'1': 'blocks_json', '3': 2, '4': 1, '5': 9, '10': 'blocksJson'},
  ],
};

/// Descriptor for `ResConsumptionPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resConsumptionPutDescriptor = $convert.base64Decode(
    'ChFSZXNDb25zdW1wdGlvblB1dBIyCgtjb25zdW1wdGlvbhgBIAEoCzIQLmMzNS5Db25zdW1wdG'
    'lvblILY29uc3VtcHRpb24SHwoLYmxvY2tzX2pzb24YAiABKAlSCmJsb2Nrc0pzb24=');

@$core.Deprecated('Use reqConsumptionWaterGetDescriptor instead')
const ReqConsumptionWaterGet$json = {
  '1': 'ReqConsumptionWaterGet',
  '2': [
    {'1': 'day_id', '3': 1, '4': 1, '5': 9, '10': 'dayId'},
  ],
};

/// Descriptor for `ReqConsumptionWaterGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqConsumptionWaterGetDescriptor =
    $convert.base64Decode(
        'ChZSZXFDb25zdW1wdGlvbldhdGVyR2V0EhUKBmRheV9pZBgBIAEoCVIFZGF5SWQ=');

@$core.Deprecated('Use resConsumptionWaterGetDescriptor instead')
const ResConsumptionWaterGet$json = {
  '1': 'ResConsumptionWaterGet',
  '2': [
    {
      '1': 'water',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.ConsumptionWater',
      '10': 'water'
    },
  ],
};

/// Descriptor for `ResConsumptionWaterGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resConsumptionWaterGetDescriptor =
    $convert.base64Decode(
        'ChZSZXNDb25zdW1wdGlvbldhdGVyR2V0EisKBXdhdGVyGAEgASgLMhUuYzM1LkNvbnN1bXB0aW'
        '9uV2F0ZXJSBXdhdGVy');

@$core.Deprecated('Use reqConsumptionWaterAddDescriptor instead')
const ReqConsumptionWaterAdd$json = {
  '1': 'ReqConsumptionWaterAdd',
  '2': [
    {'1': 'day_id', '3': 1, '4': 1, '5': 9, '10': 'dayId'},
    {'1': 'ml', '3': 2, '4': 1, '5': 5, '10': 'ml'},
  ],
};

/// Descriptor for `ReqConsumptionWaterAdd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqConsumptionWaterAddDescriptor =
    $convert.base64Decode(
        'ChZSZXFDb25zdW1wdGlvbldhdGVyQWRkEhUKBmRheV9pZBgBIAEoCVIFZGF5SWQSDgoCbWwYAi'
        'ABKAVSAm1s');

@$core.Deprecated('Use resConsumptionWaterAddDescriptor instead')
const ResConsumptionWaterAdd$json = {
  '1': 'ResConsumptionWaterAdd',
  '2': [
    {
      '1': 'water',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.ConsumptionWater',
      '10': 'water'
    },
  ],
};

/// Descriptor for `ResConsumptionWaterAdd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resConsumptionWaterAddDescriptor =
    $convert.base64Decode(
        'ChZSZXNDb25zdW1wdGlvbldhdGVyQWRkEisKBXdhdGVyGAEgASgLMhUuYzM1LkNvbnN1bXB0aW'
        '9uV2F0ZXJSBXdhdGVy');

@$core.Deprecated('Use reqConsumptionPrefsGetDescriptor instead')
const ReqConsumptionPrefsGet$json = {
  '1': 'ReqConsumptionPrefsGet',
};

/// Descriptor for `ReqConsumptionPrefsGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqConsumptionPrefsGetDescriptor =
    $convert.base64Decode('ChZSZXFDb25zdW1wdGlvblByZWZzR2V0');

@$core.Deprecated('Use resConsumptionPrefsGetDescriptor instead')
const ResConsumptionPrefsGet$json = {
  '1': 'ResConsumptionPrefsGet',
  '2': [
    {
      '1': 'prefs',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.ConsumptionPrefs',
      '10': 'prefs'
    },
  ],
};

/// Descriptor for `ResConsumptionPrefsGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resConsumptionPrefsGetDescriptor =
    $convert.base64Decode(
        'ChZSZXNDb25zdW1wdGlvblByZWZzR2V0EisKBXByZWZzGAEgASgLMhUuYzM1LkNvbnN1bXB0aW'
        '9uUHJlZnNSBXByZWZz');

@$core.Deprecated('Use reqConsumptionPrefsPutDescriptor instead')
const ReqConsumptionPrefsPut$json = {
  '1': 'ReqConsumptionPrefsPut',
  '2': [
    {
      '1': 'prefs',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.ConsumptionPrefs',
      '10': 'prefs'
    },
  ],
};

/// Descriptor for `ReqConsumptionPrefsPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqConsumptionPrefsPutDescriptor =
    $convert.base64Decode(
        'ChZSZXFDb25zdW1wdGlvblByZWZzUHV0EisKBXByZWZzGAEgASgLMhUuYzM1LkNvbnN1bXB0aW'
        '9uUHJlZnNSBXByZWZz');

@$core.Deprecated('Use resConsumptionPrefsPutDescriptor instead')
const ResConsumptionPrefsPut$json = {
  '1': 'ResConsumptionPrefsPut',
  '2': [
    {
      '1': 'prefs',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.ConsumptionPrefs',
      '10': 'prefs'
    },
  ],
};

/// Descriptor for `ResConsumptionPrefsPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resConsumptionPrefsPutDescriptor =
    $convert.base64Decode(
        'ChZSZXNDb25zdW1wdGlvblByZWZzUHV0EisKBXByZWZzGAEgASgLMhUuYzM1LkNvbnN1bXB0aW'
        '9uUHJlZnNSBXByZWZz');
