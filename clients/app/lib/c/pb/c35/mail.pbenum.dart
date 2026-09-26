// This is a generated file - do not edit.
//
// Generated from c35/mail.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class MailDirection extends $pb.ProtobufEnum {
  static const MailDirection MAIL_DIRECTION_UNSPECIFIED =
      MailDirection._(0, _omitEnumNames ? '' : 'MAIL_DIRECTION_UNSPECIFIED');
  static const MailDirection MAIL_DIRECTION_IN =
      MailDirection._(1, _omitEnumNames ? '' : 'MAIL_DIRECTION_IN');
  static const MailDirection MAIL_DIRECTION_OUT =
      MailDirection._(2, _omitEnumNames ? '' : 'MAIL_DIRECTION_OUT');

  static const $core.List<MailDirection> values = <MailDirection>[
    MAIL_DIRECTION_UNSPECIFIED,
    MAIL_DIRECTION_IN,
    MAIL_DIRECTION_OUT,
  ];

  static final $core.List<MailDirection?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static MailDirection? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MailDirection._(super.value, super.name);
}

class MailStatus extends $pb.ProtobufEnum {
  static const MailStatus MAIL_STATUS_UNSPECIFIED =
      MailStatus._(0, _omitEnumNames ? '' : 'MAIL_STATUS_UNSPECIFIED');
  static const MailStatus MAIL_STATUS_RECEIVED =
      MailStatus._(1, _omitEnumNames ? '' : 'MAIL_STATUS_RECEIVED');
  static const MailStatus MAIL_STATUS_QUEUED =
      MailStatus._(2, _omitEnumNames ? '' : 'MAIL_STATUS_QUEUED');
  static const MailStatus MAIL_STATUS_SENT =
      MailStatus._(3, _omitEnumNames ? '' : 'MAIL_STATUS_SENT');
  static const MailStatus MAIL_STATUS_FAILED =
      MailStatus._(4, _omitEnumNames ? '' : 'MAIL_STATUS_FAILED');

  static const $core.List<MailStatus> values = <MailStatus>[
    MAIL_STATUS_UNSPECIFIED,
    MAIL_STATUS_RECEIVED,
    MAIL_STATUS_QUEUED,
    MAIL_STATUS_SENT,
    MAIL_STATUS_FAILED,
  ];

  static final $core.List<MailStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static MailStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MailStatus._(super.value, super.name);
}

class MailMailboxKind extends $pb.ProtobufEnum {
  static const MailMailboxKind MAIL_MAILBOX_KIND_UNSPECIFIED =
      MailMailboxKind._(
          0, _omitEnumNames ? '' : 'MAIL_MAILBOX_KIND_UNSPECIFIED');
  static const MailMailboxKind MAIL_MAILBOX_KIND_PERSONAL =
      MailMailboxKind._(1, _omitEnumNames ? '' : 'MAIL_MAILBOX_KIND_PERSONAL');
  static const MailMailboxKind MAIL_MAILBOX_KIND_SITE =
      MailMailboxKind._(2, _omitEnumNames ? '' : 'MAIL_MAILBOX_KIND_SITE');

  static const $core.List<MailMailboxKind> values = <MailMailboxKind>[
    MAIL_MAILBOX_KIND_UNSPECIFIED,
    MAIL_MAILBOX_KIND_PERSONAL,
    MAIL_MAILBOX_KIND_SITE,
  ];

  static final $core.List<MailMailboxKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static MailMailboxKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MailMailboxKind._(super.value, super.name);
}

class MailMailboxAccess extends $pb.ProtobufEnum {
  static const MailMailboxAccess MAIL_MAILBOX_ACCESS_UNSPECIFIED =
      MailMailboxAccess._(
          0, _omitEnumNames ? '' : 'MAIL_MAILBOX_ACCESS_UNSPECIFIED');
  static const MailMailboxAccess MAIL_MAILBOX_ACCESS_READ =
      MailMailboxAccess._(1, _omitEnumNames ? '' : 'MAIL_MAILBOX_ACCESS_READ');
  static const MailMailboxAccess MAIL_MAILBOX_ACCESS_WRITE =
      MailMailboxAccess._(2, _omitEnumNames ? '' : 'MAIL_MAILBOX_ACCESS_WRITE');

  static const $core.List<MailMailboxAccess> values = <MailMailboxAccess>[
    MAIL_MAILBOX_ACCESS_UNSPECIFIED,
    MAIL_MAILBOX_ACCESS_READ,
    MAIL_MAILBOX_ACCESS_WRITE,
  ];

  static final $core.List<MailMailboxAccess?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static MailMailboxAccess? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MailMailboxAccess._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
