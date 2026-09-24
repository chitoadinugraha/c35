// This is a generated file - do not edit.
//
// Generated from c35/report.proto.

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

@$core.Deprecated('Use uiMetricsCardDescriptor instead')
const UiMetricsCard$json = {
  '1': 'UiMetricsCard',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
    {'1': 'subtitle', '3': 3, '4': 1, '5': 9, '10': 'subtitle'},
  ],
};

/// Descriptor for `UiMetricsCard`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uiMetricsCardDescriptor = $convert.base64Decode(
    'Cg1VaU1ldHJpY3NDYXJkEhQKBXRpdGxlGAEgASgJUgV0aXRsZRIUCgV2YWx1ZRgCIAEoCVIFdm'
    'FsdWUSGgoIc3VidGl0bGUYAyABKAlSCHN1YnRpdGxl');

@$core.Deprecated('Use uiReportTableDescriptor instead')
const UiReportTable$json = {
  '1': 'UiReportTable',
  '2': [
    {'1': 'headers', '3': 1, '4': 3, '5': 9, '10': 'headers'},
    {
      '1': 'rows',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.UiReportTableRow',
      '10': 'rows'
    },
  ],
};

/// Descriptor for `UiReportTable`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uiReportTableDescriptor = $convert.base64Decode(
    'Cg1VaVJlcG9ydFRhYmxlEhgKB2hlYWRlcnMYASADKAlSB2hlYWRlcnMSKQoEcm93cxgCIAMoCz'
    'IVLmMzNS5VaVJlcG9ydFRhYmxlUm93UgRyb3dz');

@$core.Deprecated('Use uiReportTableRowDescriptor instead')
const UiReportTableRow$json = {
  '1': 'UiReportTableRow',
  '2': [
    {'1': 'cells', '3': 1, '4': 3, '5': 9, '10': 'cells'},
  ],
};

/// Descriptor for `UiReportTableRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uiReportTableRowDescriptor = $convert
    .base64Decode('ChBVaVJlcG9ydFRhYmxlUm93EhQKBWNlbGxzGAEgAygJUgVjZWxscw==');

@$core.Deprecated('Use uiWidgetDescriptor instead')
const UiWidget$json = {
  '1': 'UiWidget',
  '2': [
    {
      '1': 'metrics_card',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.UiMetricsCard',
      '9': 0,
      '10': 'metricsCard'
    },
    {
      '1': 'table',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.UiReportTable',
      '9': 0,
      '10': 'table'
    },
  ],
  '8': [
    {'1': 'element'},
  ],
};

/// Descriptor for `UiWidget`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uiWidgetDescriptor = $convert.base64Decode(
    'CghVaVdpZGdldBI3CgxtZXRyaWNzX2NhcmQYASABKAsyEi5jMzUuVWlNZXRyaWNzQ2FyZEgAUg'
    'ttZXRyaWNzQ2FyZBIqCgV0YWJsZRgCIAEoCzISLmMzNS5VaVJlcG9ydFRhYmxlSABSBXRhYmxl'
    'QgkKB2VsZW1lbnQ=');

@$core.Deprecated('Use reqAdminLogReportDescriptor instead')
const ReqAdminLogReport$json = {
  '1': 'ReqAdminLogReport',
  '2': [
    {
      '1': 'owner_iid',
      '3': 1,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'ownerIid',
      '17': true
    },
    {'1': 'since_ms', '3': 2, '4': 1, '5': 3, '10': 'sinceMs'},
    {'1': 'until_ms', '3': 3, '4': 1, '5': 3, '10': 'untilMs'},
    {'1': 'limit', '3': 4, '4': 1, '5': 5, '10': 'limit'},
  ],
  '8': [
    {'1': '_owner_iid'},
  ],
};

/// Descriptor for `ReqAdminLogReport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqAdminLogReportDescriptor = $convert.base64Decode(
    'ChFSZXFBZG1pbkxvZ1JlcG9ydBIgCglvd25lcl9paWQYASABKANIAFIIb3duZXJJaWSIAQESGQ'
    'oIc2luY2VfbXMYAiABKANSB3NpbmNlTXMSGQoIdW50aWxfbXMYAyABKANSB3VudGlsTXMSFAoF'
    'bGltaXQYBCABKAVSBWxpbWl0QgwKCl9vd25lcl9paWQ=');

@$core.Deprecated('Use resAdminLogReportDescriptor instead')
const ResAdminLogReport$json = {
  '1': 'ResAdminLogReport',
  '2': [
    {
      '1': 'widgets',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.UiWidget',
      '10': 'widgets'
    },
  ],
};

/// Descriptor for `ResAdminLogReport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resAdminLogReportDescriptor = $convert.base64Decode(
    'ChFSZXNBZG1pbkxvZ1JlcG9ydBInCgd3aWRnZXRzGAEgAygLMg0uYzM1LlVpV2lkZ2V0Ugd3aW'
    'RnZXRz');

@$core.Deprecated('Use reqAdminPlatformPnlDescriptor instead')
const ReqAdminPlatformPnl$json = {
  '1': 'ReqAdminPlatformPnl',
  '2': [
    {'1': 'since_ms', '3': 1, '4': 1, '5': 3, '10': 'sinceMs'},
    {'1': 'until_ms', '3': 2, '4': 1, '5': 3, '10': 'untilMs'},
  ],
};

/// Descriptor for `ReqAdminPlatformPnl`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqAdminPlatformPnlDescriptor = $convert.base64Decode(
    'ChNSZXFBZG1pblBsYXRmb3JtUG5sEhkKCHNpbmNlX21zGAEgASgDUgdzaW5jZU1zEhkKCHVudG'
    'lsX21zGAIgASgDUgd1bnRpbE1z');

@$core.Deprecated('Use resAdminPlatformPnlDescriptor instead')
const ResAdminPlatformPnl$json = {
  '1': 'ResAdminPlatformPnl',
  '2': [
    {
      '1': 'widgets',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.UiWidget',
      '10': 'widgets'
    },
    {'1': 'revenue_usd', '3': 2, '4': 1, '5': 1, '10': 'revenueUsd'},
    {'1': 'ai_cogs_usd', '3': 3, '4': 1, '5': 1, '10': 'aiCogsUsd'},
    {'1': 'infra_cogs_usd', '3': 4, '4': 1, '5': 1, '10': 'infraCogsUsd'},
    {'1': 'gross_profit_usd', '3': 5, '4': 1, '5': 1, '10': 'grossProfitUsd'},
    {'1': 'ai_api_vendor_usd', '3': 6, '4': 1, '5': 1, '10': 'aiApiVendorUsd'},
    {'1': 'ai_cogs_drift_pct', '3': 7, '4': 1, '5': 1, '10': 'aiCogsDriftPct'},
  ],
};

/// Descriptor for `ResAdminPlatformPnl`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resAdminPlatformPnlDescriptor = $convert.base64Decode(
    'ChNSZXNBZG1pblBsYXRmb3JtUG5sEicKB3dpZGdldHMYASADKAsyDS5jMzUuVWlXaWRnZXRSB3'
    'dpZGdldHMSHwoLcmV2ZW51ZV91c2QYAiABKAFSCnJldmVudWVVc2QSHgoLYWlfY29nc191c2QY'
    'AyABKAFSCWFpQ29nc1VzZBIkCg5pbmZyYV9jb2dzX3VzZBgEIAEoAVIMaW5mcmFDb2dzVXNkEi'
    'gKEGdyb3NzX3Byb2ZpdF91c2QYBSABKAFSDmdyb3NzUHJvZml0VXNkEikKEWFpX2FwaV92ZW5k'
    'b3JfdXNkGAYgASgBUg5haUFwaVZlbmRvclVzZBIpChFhaV9jb2dzX2RyaWZ0X3BjdBgHIAEoAV'
    'IOYWlDb2dzRHJpZnRQY3Q=');
