// This is a generated file - do not edit.
//
// Generated from c35/consumption.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'consumption.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'consumption.pbenum.dart';

class Nutrition extends $pb.GeneratedMessage {
  factory Nutrition({
    $core.int? calories,
    $core.int? protein,
    $core.int? fat,
    $core.int? carbs,
    $core.int? fiber,
    $core.int? sugar,
    $core.int? sodium,
    $core.int? potassium,
    $core.int? vitaminA,
    $core.int? vitaminC,
    $core.int? vitaminD,
    $core.int? vitaminE,
    $core.int? vitaminK,
    $core.int? calcium,
    $core.int? iron,
    $core.int? magnesium,
    $core.int? phosphorus,
    $core.int? zinc,
    $core.int? copper,
    $core.int? cholesterol,
    $core.int? purines,
  }) {
    final result = Nutrition._();
    if (calories != null) result.calories = calories;
    if (protein != null) result.protein = protein;
    if (fat != null) result.fat = fat;
    if (carbs != null) result.carbs = carbs;
    if (fiber != null) result.fiber = fiber;
    if (sugar != null) result.sugar = sugar;
    if (sodium != null) result.sodium = sodium;
    if (potassium != null) result.potassium = potassium;
    if (vitaminA != null) result.vitaminA = vitaminA;
    if (vitaminC != null) result.vitaminC = vitaminC;
    if (vitaminD != null) result.vitaminD = vitaminD;
    if (vitaminE != null) result.vitaminE = vitaminE;
    if (vitaminK != null) result.vitaminK = vitaminK;
    if (calcium != null) result.calcium = calcium;
    if (iron != null) result.iron = iron;
    if (magnesium != null) result.magnesium = magnesium;
    if (phosphorus != null) result.phosphorus = phosphorus;
    if (zinc != null) result.zinc = zinc;
    if (copper != null) result.copper = copper;
    if (cholesterol != null) result.cholesterol = cholesterol;
    if (purines != null) result.purines = purines;
    return result;
  }

  Nutrition._();

  factory Nutrition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Nutrition()..mergeFromBuffer(data, registry);
  factory Nutrition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Nutrition()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Nutrition',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: Nutrition.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'calories')
    ..aI(2, _omitFieldNames ? '' : 'protein')
    ..aI(3, _omitFieldNames ? '' : 'fat')
    ..aI(4, _omitFieldNames ? '' : 'carbs')
    ..aI(5, _omitFieldNames ? '' : 'fiber')
    ..aI(6, _omitFieldNames ? '' : 'sugar')
    ..aI(7, _omitFieldNames ? '' : 'sodium')
    ..aI(8, _omitFieldNames ? '' : 'potassium')
    ..aI(9, _omitFieldNames ? '' : 'vitaminA')
    ..aI(10, _omitFieldNames ? '' : 'vitaminC')
    ..aI(11, _omitFieldNames ? '' : 'vitaminD')
    ..aI(12, _omitFieldNames ? '' : 'vitaminE')
    ..aI(13, _omitFieldNames ? '' : 'vitaminK')
    ..aI(14, _omitFieldNames ? '' : 'calcium')
    ..aI(15, _omitFieldNames ? '' : 'iron')
    ..aI(16, _omitFieldNames ? '' : 'magnesium')
    ..aI(17, _omitFieldNames ? '' : 'phosphorus')
    ..aI(18, _omitFieldNames ? '' : 'zinc')
    ..aI(19, _omitFieldNames ? '' : 'copper')
    ..aI(20, _omitFieldNames ? '' : 'cholesterol')
    ..aI(21, _omitFieldNames ? '' : 'purines')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Nutrition clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Nutrition copyWith(void Function(Nutrition) updates) =>
      super.copyWith((message) => updates(message as Nutrition)) as Nutrition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Nutrition() / Nutrition.new instead')
  static Nutrition create() => Nutrition._();
  static $pb.GeneratedMessage $_createMessage() => Nutrition._();
  @$core.override
  Nutrition createEmptyInstance() => Nutrition._();
  @$core.pragma('dart2js:noInline')
  static Nutrition getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Nutrition>(Nutrition.$_createMessage);
  static Nutrition? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get calories => $_getIZ(0);
  @$pb.TagNumber(1)
  set calories($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCalories() => $_has(0);
  @$pb.TagNumber(1)
  void clearCalories() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get protein => $_getIZ(1);
  @$pb.TagNumber(2)
  set protein($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProtein() => $_has(1);
  @$pb.TagNumber(2)
  void clearProtein() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get fat => $_getIZ(2);
  @$pb.TagNumber(3)
  set fat($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFat() => $_has(2);
  @$pb.TagNumber(3)
  void clearFat() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get carbs => $_getIZ(3);
  @$pb.TagNumber(4)
  set carbs($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCarbs() => $_has(3);
  @$pb.TagNumber(4)
  void clearCarbs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get fiber => $_getIZ(4);
  @$pb.TagNumber(5)
  set fiber($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFiber() => $_has(4);
  @$pb.TagNumber(5)
  void clearFiber() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get sugar => $_getIZ(5);
  @$pb.TagNumber(6)
  set sugar($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSugar() => $_has(5);
  @$pb.TagNumber(6)
  void clearSugar() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get sodium => $_getIZ(6);
  @$pb.TagNumber(7)
  set sodium($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSodium() => $_has(6);
  @$pb.TagNumber(7)
  void clearSodium() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get potassium => $_getIZ(7);
  @$pb.TagNumber(8)
  set potassium($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPotassium() => $_has(7);
  @$pb.TagNumber(8)
  void clearPotassium() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get vitaminA => $_getIZ(8);
  @$pb.TagNumber(9)
  set vitaminA($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasVitaminA() => $_has(8);
  @$pb.TagNumber(9)
  void clearVitaminA() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get vitaminC => $_getIZ(9);
  @$pb.TagNumber(10)
  set vitaminC($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasVitaminC() => $_has(9);
  @$pb.TagNumber(10)
  void clearVitaminC() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get vitaminD => $_getIZ(10);
  @$pb.TagNumber(11)
  set vitaminD($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasVitaminD() => $_has(10);
  @$pb.TagNumber(11)
  void clearVitaminD() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get vitaminE => $_getIZ(11);
  @$pb.TagNumber(12)
  set vitaminE($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasVitaminE() => $_has(11);
  @$pb.TagNumber(12)
  void clearVitaminE() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get vitaminK => $_getIZ(12);
  @$pb.TagNumber(13)
  set vitaminK($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasVitaminK() => $_has(12);
  @$pb.TagNumber(13)
  void clearVitaminK() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.int get calcium => $_getIZ(13);
  @$pb.TagNumber(14)
  set calcium($core.int value) => $_setSignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCalcium() => $_has(13);
  @$pb.TagNumber(14)
  void clearCalcium() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.int get iron => $_getIZ(14);
  @$pb.TagNumber(15)
  set iron($core.int value) => $_setSignedInt32(14, value);
  @$pb.TagNumber(15)
  $core.bool hasIron() => $_has(14);
  @$pb.TagNumber(15)
  void clearIron() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.int get magnesium => $_getIZ(15);
  @$pb.TagNumber(16)
  set magnesium($core.int value) => $_setSignedInt32(15, value);
  @$pb.TagNumber(16)
  $core.bool hasMagnesium() => $_has(15);
  @$pb.TagNumber(16)
  void clearMagnesium() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.int get phosphorus => $_getIZ(16);
  @$pb.TagNumber(17)
  set phosphorus($core.int value) => $_setSignedInt32(16, value);
  @$pb.TagNumber(17)
  $core.bool hasPhosphorus() => $_has(16);
  @$pb.TagNumber(17)
  void clearPhosphorus() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.int get zinc => $_getIZ(17);
  @$pb.TagNumber(18)
  set zinc($core.int value) => $_setSignedInt32(17, value);
  @$pb.TagNumber(18)
  $core.bool hasZinc() => $_has(17);
  @$pb.TagNumber(18)
  void clearZinc() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.int get copper => $_getIZ(18);
  @$pb.TagNumber(19)
  set copper($core.int value) => $_setSignedInt32(18, value);
  @$pb.TagNumber(19)
  $core.bool hasCopper() => $_has(18);
  @$pb.TagNumber(19)
  void clearCopper() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.int get cholesterol => $_getIZ(19);
  @$pb.TagNumber(20)
  set cholesterol($core.int value) => $_setSignedInt32(19, value);
  @$pb.TagNumber(20)
  $core.bool hasCholesterol() => $_has(19);
  @$pb.TagNumber(20)
  void clearCholesterol() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.int get purines => $_getIZ(20);
  @$pb.TagNumber(21)
  set purines($core.int value) => $_setSignedInt32(20, value);
  @$pb.TagNumber(21)
  $core.bool hasPurines() => $_has(20);
  @$pb.TagNumber(21)
  void clearPurines() => $_clearField(21);
}

class ConsumptionItem extends $pb.GeneratedMessage {
  factory ConsumptionItem({
    $core.int? idx,
    $core.String? name,
    $core.String? nameId,
    $core.double? qty,
    $core.String? pic,
    Nutrition? nutrition,
  }) {
    final result = ConsumptionItem._();
    if (idx != null) result.idx = idx;
    if (name != null) result.name = name;
    if (nameId != null) result.nameId = nameId;
    if (qty != null) result.qty = qty;
    if (pic != null) result.pic = pic;
    if (nutrition != null) result.nutrition = nutrition;
    return result;
  }

  ConsumptionItem._();

  factory ConsumptionItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConsumptionItem()..mergeFromBuffer(data, registry);
  factory ConsumptionItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConsumptionItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConsumptionItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ConsumptionItem.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'idx')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'nameId')
    ..aD(4, _omitFieldNames ? '' : 'qty', fieldType: $pb.PbFieldType.OF)
    ..aOS(5, _omitFieldNames ? '' : 'pic')
    ..aOM<Nutrition>(6, _omitFieldNames ? '' : 'nutrition',
        subBuilder: Nutrition.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConsumptionItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConsumptionItem copyWith(void Function(ConsumptionItem) updates) =>
      super.copyWith((message) => updates(message as ConsumptionItem))
          as ConsumptionItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConsumptionItem() / ConsumptionItem.new instead')
  static ConsumptionItem create() => ConsumptionItem._();
  static $pb.GeneratedMessage $_createMessage() => ConsumptionItem._();
  @$core.override
  ConsumptionItem createEmptyInstance() => ConsumptionItem._();
  @$core.pragma('dart2js:noInline')
  static ConsumptionItem getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConsumptionItem>(
          ConsumptionItem.$_createMessage);
  static ConsumptionItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get idx => $_getIZ(0);
  @$pb.TagNumber(1)
  set idx($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdx() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdx() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get nameId => $_getSZ(2);
  @$pb.TagNumber(3)
  set nameId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNameId() => $_has(2);
  @$pb.TagNumber(3)
  void clearNameId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get qty => $_getN(3);
  @$pb.TagNumber(4)
  set qty($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasQty() => $_has(3);
  @$pb.TagNumber(4)
  void clearQty() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get pic => $_getSZ(4);
  @$pb.TagNumber(5)
  set pic($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPic() => $_has(4);
  @$pb.TagNumber(5)
  void clearPic() => $_clearField(5);

  @$pb.TagNumber(6)
  Nutrition get nutrition => $_getN(5);
  @$pb.TagNumber(6)
  set nutrition(Nutrition value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasNutrition() => $_has(5);
  @$pb.TagNumber(6)
  void clearNutrition() => $_clearField(6);
  @$pb.TagNumber(6)
  Nutrition ensureNutrition() => $_ensure(5);
}

class Consumption extends $pb.GeneratedMessage {
  factory Consumption({
    $fixnum.Int64? id,
    $fixnum.Int64? ownerIid,
    $core.String? note,
    $core.String? photoHash,
    $core.String? mealFingerprint,
    ConsumeMealType? mealType,
    $core.Iterable<$core.String>? pics,
    $fixnum.Int64? loggedTsMs,
    $core.bool? isArchived,
    $core.Iterable<ConsumptionItem>? items,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = Consumption._();
    if (id != null) result.id = id;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (note != null) result.note = note;
    if (photoHash != null) result.photoHash = photoHash;
    if (mealFingerprint != null) result.mealFingerprint = mealFingerprint;
    if (mealType != null) result.mealType = mealType;
    if (pics != null) result.pics.addAll(pics);
    if (loggedTsMs != null) result.loggedTsMs = loggedTsMs;
    if (isArchived != null) result.isArchived = isArchived;
    if (items != null) result.items.addAll(items);
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  Consumption._();

  factory Consumption.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Consumption()..mergeFromBuffer(data, registry);
  factory Consumption.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Consumption()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Consumption',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: Consumption.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(3, _omitFieldNames ? '' : 'note')
    ..aOS(4, _omitFieldNames ? '' : 'photoHash')
    ..aOS(5, _omitFieldNames ? '' : 'mealFingerprint')
    ..aE<ConsumeMealType>(6, _omitFieldNames ? '' : 'mealType',
        enumValues: ConsumeMealType.values)
    ..pPS(7, _omitFieldNames ? '' : 'pics')
    ..aInt64(8, _omitFieldNames ? '' : 'loggedTsMs')
    ..aOB(9, _omitFieldNames ? '' : 'isArchived')
    ..pPM<ConsumptionItem>(10, _omitFieldNames ? '' : 'items',
        subBuilder: ConsumptionItem.$_createMessage)
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Consumption clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Consumption copyWith(void Function(Consumption) updates) =>
      super.copyWith((message) => updates(message as Consumption))
          as Consumption;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Consumption() / Consumption.new instead')
  static Consumption create() => Consumption._();
  static $pb.GeneratedMessage $_createMessage() => Consumption._();
  @$core.override
  Consumption createEmptyInstance() => Consumption._();
  @$core.pragma('dart2js:noInline')
  static Consumption getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Consumption>(
          Consumption.$_createMessage);
  static Consumption? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get note => $_getSZ(2);
  @$pb.TagNumber(3)
  set note($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNote() => $_has(2);
  @$pb.TagNumber(3)
  void clearNote() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get photoHash => $_getSZ(3);
  @$pb.TagNumber(4)
  set photoHash($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPhotoHash() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhotoHash() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get mealFingerprint => $_getSZ(4);
  @$pb.TagNumber(5)
  set mealFingerprint($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMealFingerprint() => $_has(4);
  @$pb.TagNumber(5)
  void clearMealFingerprint() => $_clearField(5);

  @$pb.TagNumber(6)
  ConsumeMealType get mealType => $_getN(5);
  @$pb.TagNumber(6)
  set mealType(ConsumeMealType value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasMealType() => $_has(5);
  @$pb.TagNumber(6)
  void clearMealType() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get pics => $_getList(6);

  @$pb.TagNumber(8)
  $fixnum.Int64 get loggedTsMs => $_getI64(7);
  @$pb.TagNumber(8)
  set loggedTsMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLoggedTsMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearLoggedTsMs() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get isArchived => $_getBF(8);
  @$pb.TagNumber(9)
  set isArchived($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasIsArchived() => $_has(8);
  @$pb.TagNumber(9)
  void clearIsArchived() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbList<ConsumptionItem> get items => $_getList(9);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(10);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(10);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(11);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(11);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(12);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(12);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
}

class ConsumptionWater extends $pb.GeneratedMessage {
  factory ConsumptionWater({
    $fixnum.Int64? ownerIid,
    $core.String? dayId,
    $core.int? ml,
    $core.int? goalMl,
    $core.int? entryCount,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = ConsumptionWater._();
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (dayId != null) result.dayId = dayId;
    if (ml != null) result.ml = ml;
    if (goalMl != null) result.goalMl = goalMl;
    if (entryCount != null) result.entryCount = entryCount;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  ConsumptionWater._();

  factory ConsumptionWater.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConsumptionWater()..mergeFromBuffer(data, registry);
  factory ConsumptionWater.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConsumptionWater()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConsumptionWater',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ConsumptionWater.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(2, _omitFieldNames ? '' : 'dayId')
    ..aI(3, _omitFieldNames ? '' : 'ml')
    ..aI(4, _omitFieldNames ? '' : 'goalMl')
    ..aI(5, _omitFieldNames ? '' : 'entryCount')
    ..aInt64(10, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(11, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(12, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConsumptionWater clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConsumptionWater copyWith(void Function(ConsumptionWater) updates) =>
      super.copyWith((message) => updates(message as ConsumptionWater))
          as ConsumptionWater;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConsumptionWater() / ConsumptionWater.new instead')
  static ConsumptionWater create() => ConsumptionWater._();
  static $pb.GeneratedMessage $_createMessage() => ConsumptionWater._();
  @$core.override
  ConsumptionWater createEmptyInstance() => ConsumptionWater._();
  @$core.pragma('dart2js:noInline')
  static ConsumptionWater getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConsumptionWater>(
          ConsumptionWater.$_createMessage);
  static ConsumptionWater? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get ownerIid => $_getI64(0);
  @$pb.TagNumber(1)
  set ownerIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOwnerIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearOwnerIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get dayId => $_getSZ(1);
  @$pb.TagNumber(2)
  set dayId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDayId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDayId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get ml => $_getIZ(2);
  @$pb.TagNumber(3)
  set ml($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMl() => $_has(2);
  @$pb.TagNumber(3)
  void clearMl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get goalMl => $_getIZ(3);
  @$pb.TagNumber(4)
  set goalMl($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGoalMl() => $_has(3);
  @$pb.TagNumber(4)
  void clearGoalMl() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get entryCount => $_getIZ(4);
  @$pb.TagNumber(5)
  set entryCount($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEntryCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearEntryCount() => $_clearField(5);

  @$pb.TagNumber(10)
  $fixnum.Int64 get createdTsMs => $_getI64(5);
  @$pb.TagNumber(10)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(10)
  $core.bool hasCreatedTsMs() => $_has(5);
  @$pb.TagNumber(10)
  void clearCreatedTsMs() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get updatedTsMs => $_getI64(6);
  @$pb.TagNumber(11)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(11)
  $core.bool hasUpdatedTsMs() => $_has(6);
  @$pb.TagNumber(11)
  void clearUpdatedTsMs() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get deletedTsMs => $_getI64(7);
  @$pb.TagNumber(12)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(12)
  $core.bool hasDeletedTsMs() => $_has(7);
  @$pb.TagNumber(12)
  void clearDeletedTsMs() => $_clearField(12);
}

class ConsumptionPrefs extends $pb.GeneratedMessage {
  factory ConsumptionPrefs({
    $fixnum.Int64? ownerIid,
    $core.int? calorieGoalKcal,
    $core.int? waterGoalMl,
    $fixnum.Int64? updatedTsMs,
  }) {
    final result = ConsumptionPrefs._();
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (calorieGoalKcal != null) result.calorieGoalKcal = calorieGoalKcal;
    if (waterGoalMl != null) result.waterGoalMl = waterGoalMl;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    return result;
  }

  ConsumptionPrefs._();

  factory ConsumptionPrefs.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConsumptionPrefs()..mergeFromBuffer(data, registry);
  factory ConsumptionPrefs.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConsumptionPrefs()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConsumptionPrefs',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ConsumptionPrefs.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'ownerIid')
    ..aI(2, _omitFieldNames ? '' : 'calorieGoalKcal')
    ..aI(3, _omitFieldNames ? '' : 'waterGoalMl')
    ..aInt64(4, _omitFieldNames ? '' : 'updatedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConsumptionPrefs clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConsumptionPrefs copyWith(void Function(ConsumptionPrefs) updates) =>
      super.copyWith((message) => updates(message as ConsumptionPrefs))
          as ConsumptionPrefs;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConsumptionPrefs() / ConsumptionPrefs.new instead')
  static ConsumptionPrefs create() => ConsumptionPrefs._();
  static $pb.GeneratedMessage $_createMessage() => ConsumptionPrefs._();
  @$core.override
  ConsumptionPrefs createEmptyInstance() => ConsumptionPrefs._();
  @$core.pragma('dart2js:noInline')
  static ConsumptionPrefs getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConsumptionPrefs>(
          ConsumptionPrefs.$_createMessage);
  static ConsumptionPrefs? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get ownerIid => $_getI64(0);
  @$pb.TagNumber(1)
  set ownerIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOwnerIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearOwnerIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get calorieGoalKcal => $_getIZ(1);
  @$pb.TagNumber(2)
  set calorieGoalKcal($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCalorieGoalKcal() => $_has(1);
  @$pb.TagNumber(2)
  void clearCalorieGoalKcal() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get waterGoalMl => $_getIZ(2);
  @$pb.TagNumber(3)
  set waterGoalMl($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWaterGoalMl() => $_has(2);
  @$pb.TagNumber(3)
  void clearWaterGoalMl() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get updatedTsMs => $_getI64(3);
  @$pb.TagNumber(4)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUpdatedTsMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpdatedTsMs() => $_clearField(4);
}

class ReqConsumptionList extends $pb.GeneratedMessage {
  factory ReqConsumptionList({
    $core.String? dayId,
    $fixnum.Int64? afterId,
    $core.int? limit,
  }) {
    final result = ReqConsumptionList._();
    if (dayId != null) result.dayId = dayId;
    if (afterId != null) result.afterId = afterId;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqConsumptionList._();

  factory ReqConsumptionList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqConsumptionList()..mergeFromBuffer(data, registry);
  factory ReqConsumptionList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqConsumptionList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqConsumptionList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqConsumptionList.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'dayId')
    ..aInt64(2, _omitFieldNames ? '' : 'afterId')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqConsumptionList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqConsumptionList copyWith(void Function(ReqConsumptionList) updates) =>
      super.copyWith((message) => updates(message as ReqConsumptionList))
          as ReqConsumptionList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqConsumptionList() / ReqConsumptionList.new instead')
  static ReqConsumptionList create() => ReqConsumptionList._();
  static $pb.GeneratedMessage $_createMessage() => ReqConsumptionList._();
  @$core.override
  ReqConsumptionList createEmptyInstance() => ReqConsumptionList._();
  @$core.pragma('dart2js:noInline')
  static ReqConsumptionList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqConsumptionList>(
          ReqConsumptionList.$_createMessage);
  static ReqConsumptionList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get dayId => $_getSZ(0);
  @$pb.TagNumber(1)
  set dayId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDayId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDayId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get afterId => $_getI64(1);
  @$pb.TagNumber(2)
  set afterId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAfterId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAfterId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class ResConsumptionList extends $pb.GeneratedMessage {
  factory ResConsumptionList({
    $core.Iterable<Consumption>? consumptions,
  }) {
    final result = ResConsumptionList._();
    if (consumptions != null) result.consumptions.addAll(consumptions);
    return result;
  }

  ResConsumptionList._();

  factory ResConsumptionList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResConsumptionList()..mergeFromBuffer(data, registry);
  factory ResConsumptionList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResConsumptionList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResConsumptionList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResConsumptionList.$_createMessage)
    ..pPM<Consumption>(1, _omitFieldNames ? '' : 'consumptions',
        subBuilder: Consumption.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResConsumptionList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResConsumptionList copyWith(void Function(ResConsumptionList) updates) =>
      super.copyWith((message) => updates(message as ResConsumptionList))
          as ResConsumptionList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResConsumptionList() / ResConsumptionList.new instead')
  static ResConsumptionList create() => ResConsumptionList._();
  static $pb.GeneratedMessage $_createMessage() => ResConsumptionList._();
  @$core.override
  ResConsumptionList createEmptyInstance() => ResConsumptionList._();
  @$core.pragma('dart2js:noInline')
  static ResConsumptionList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResConsumptionList>(
          ResConsumptionList.$_createMessage);
  static ResConsumptionList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Consumption> get consumptions => $_getList(0);
}

class ReqConsumptionPut extends $pb.GeneratedMessage {
  factory ReqConsumptionPut({
    Consumption? consumption,
  }) {
    final result = ReqConsumptionPut._();
    if (consumption != null) result.consumption = consumption;
    return result;
  }

  ReqConsumptionPut._();

  factory ReqConsumptionPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqConsumptionPut()..mergeFromBuffer(data, registry);
  factory ReqConsumptionPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqConsumptionPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqConsumptionPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqConsumptionPut.$_createMessage)
    ..aOM<Consumption>(1, _omitFieldNames ? '' : 'consumption',
        subBuilder: Consumption.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqConsumptionPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqConsumptionPut copyWith(void Function(ReqConsumptionPut) updates) =>
      super.copyWith((message) => updates(message as ReqConsumptionPut))
          as ReqConsumptionPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqConsumptionPut() / ReqConsumptionPut.new instead')
  static ReqConsumptionPut create() => ReqConsumptionPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqConsumptionPut._();
  @$core.override
  ReqConsumptionPut createEmptyInstance() => ReqConsumptionPut._();
  @$core.pragma('dart2js:noInline')
  static ReqConsumptionPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqConsumptionPut>(
          ReqConsumptionPut.$_createMessage);
  static ReqConsumptionPut? _defaultInstance;

  @$pb.TagNumber(1)
  Consumption get consumption => $_getN(0);
  @$pb.TagNumber(1)
  set consumption(Consumption value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConsumption() => $_has(0);
  @$pb.TagNumber(1)
  void clearConsumption() => $_clearField(1);
  @$pb.TagNumber(1)
  Consumption ensureConsumption() => $_ensure(0);
}

class ResConsumptionPut extends $pb.GeneratedMessage {
  factory ResConsumptionPut({
    Consumption? consumption,
    $core.String? blocksJson,
  }) {
    final result = ResConsumptionPut._();
    if (consumption != null) result.consumption = consumption;
    if (blocksJson != null) result.blocksJson = blocksJson;
    return result;
  }

  ResConsumptionPut._();

  factory ResConsumptionPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResConsumptionPut()..mergeFromBuffer(data, registry);
  factory ResConsumptionPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResConsumptionPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResConsumptionPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResConsumptionPut.$_createMessage)
    ..aOM<Consumption>(1, _omitFieldNames ? '' : 'consumption',
        subBuilder: Consumption.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'blocksJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResConsumptionPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResConsumptionPut copyWith(void Function(ResConsumptionPut) updates) =>
      super.copyWith((message) => updates(message as ResConsumptionPut))
          as ResConsumptionPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResConsumptionPut() / ResConsumptionPut.new instead')
  static ResConsumptionPut create() => ResConsumptionPut._();
  static $pb.GeneratedMessage $_createMessage() => ResConsumptionPut._();
  @$core.override
  ResConsumptionPut createEmptyInstance() => ResConsumptionPut._();
  @$core.pragma('dart2js:noInline')
  static ResConsumptionPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResConsumptionPut>(
          ResConsumptionPut.$_createMessage);
  static ResConsumptionPut? _defaultInstance;

  @$pb.TagNumber(1)
  Consumption get consumption => $_getN(0);
  @$pb.TagNumber(1)
  set consumption(Consumption value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConsumption() => $_has(0);
  @$pb.TagNumber(1)
  void clearConsumption() => $_clearField(1);
  @$pb.TagNumber(1)
  Consumption ensureConsumption() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get blocksJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set blocksJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBlocksJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearBlocksJson() => $_clearField(2);
}

class ReqConsumptionWaterGet extends $pb.GeneratedMessage {
  factory ReqConsumptionWaterGet({
    $core.String? dayId,
  }) {
    final result = ReqConsumptionWaterGet._();
    if (dayId != null) result.dayId = dayId;
    return result;
  }

  ReqConsumptionWaterGet._();

  factory ReqConsumptionWaterGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqConsumptionWaterGet()..mergeFromBuffer(data, registry);
  factory ReqConsumptionWaterGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqConsumptionWaterGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqConsumptionWaterGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqConsumptionWaterGet.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'dayId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqConsumptionWaterGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqConsumptionWaterGet copyWith(
          void Function(ReqConsumptionWaterGet) updates) =>
      super.copyWith((message) => updates(message as ReqConsumptionWaterGet))
          as ReqConsumptionWaterGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqConsumptionWaterGet() / ReqConsumptionWaterGet.new instead')
  static ReqConsumptionWaterGet create() => ReqConsumptionWaterGet._();
  static $pb.GeneratedMessage $_createMessage() => ReqConsumptionWaterGet._();
  @$core.override
  ReqConsumptionWaterGet createEmptyInstance() => ReqConsumptionWaterGet._();
  @$core.pragma('dart2js:noInline')
  static ReqConsumptionWaterGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqConsumptionWaterGet>(
          ReqConsumptionWaterGet.$_createMessage);
  static ReqConsumptionWaterGet? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get dayId => $_getSZ(0);
  @$pb.TagNumber(1)
  set dayId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDayId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDayId() => $_clearField(1);
}

class ResConsumptionWaterGet extends $pb.GeneratedMessage {
  factory ResConsumptionWaterGet({
    ConsumptionWater? water,
  }) {
    final result = ResConsumptionWaterGet._();
    if (water != null) result.water = water;
    return result;
  }

  ResConsumptionWaterGet._();

  factory ResConsumptionWaterGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResConsumptionWaterGet()..mergeFromBuffer(data, registry);
  factory ResConsumptionWaterGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResConsumptionWaterGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResConsumptionWaterGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResConsumptionWaterGet.$_createMessage)
    ..aOM<ConsumptionWater>(1, _omitFieldNames ? '' : 'water',
        subBuilder: ConsumptionWater.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResConsumptionWaterGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResConsumptionWaterGet copyWith(
          void Function(ResConsumptionWaterGet) updates) =>
      super.copyWith((message) => updates(message as ResConsumptionWaterGet))
          as ResConsumptionWaterGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResConsumptionWaterGet() / ResConsumptionWaterGet.new instead')
  static ResConsumptionWaterGet create() => ResConsumptionWaterGet._();
  static $pb.GeneratedMessage $_createMessage() => ResConsumptionWaterGet._();
  @$core.override
  ResConsumptionWaterGet createEmptyInstance() => ResConsumptionWaterGet._();
  @$core.pragma('dart2js:noInline')
  static ResConsumptionWaterGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResConsumptionWaterGet>(
          ResConsumptionWaterGet.$_createMessage);
  static ResConsumptionWaterGet? _defaultInstance;

  @$pb.TagNumber(1)
  ConsumptionWater get water => $_getN(0);
  @$pb.TagNumber(1)
  set water(ConsumptionWater value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasWater() => $_has(0);
  @$pb.TagNumber(1)
  void clearWater() => $_clearField(1);
  @$pb.TagNumber(1)
  ConsumptionWater ensureWater() => $_ensure(0);
}

class ReqConsumptionWaterAdd extends $pb.GeneratedMessage {
  factory ReqConsumptionWaterAdd({
    $core.String? dayId,
    $core.int? ml,
  }) {
    final result = ReqConsumptionWaterAdd._();
    if (dayId != null) result.dayId = dayId;
    if (ml != null) result.ml = ml;
    return result;
  }

  ReqConsumptionWaterAdd._();

  factory ReqConsumptionWaterAdd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqConsumptionWaterAdd()..mergeFromBuffer(data, registry);
  factory ReqConsumptionWaterAdd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqConsumptionWaterAdd()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqConsumptionWaterAdd',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqConsumptionWaterAdd.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'dayId')
    ..aI(2, _omitFieldNames ? '' : 'ml')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqConsumptionWaterAdd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqConsumptionWaterAdd copyWith(
          void Function(ReqConsumptionWaterAdd) updates) =>
      super.copyWith((message) => updates(message as ReqConsumptionWaterAdd))
          as ReqConsumptionWaterAdd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqConsumptionWaterAdd() / ReqConsumptionWaterAdd.new instead')
  static ReqConsumptionWaterAdd create() => ReqConsumptionWaterAdd._();
  static $pb.GeneratedMessage $_createMessage() => ReqConsumptionWaterAdd._();
  @$core.override
  ReqConsumptionWaterAdd createEmptyInstance() => ReqConsumptionWaterAdd._();
  @$core.pragma('dart2js:noInline')
  static ReqConsumptionWaterAdd getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqConsumptionWaterAdd>(
          ReqConsumptionWaterAdd.$_createMessage);
  static ReqConsumptionWaterAdd? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get dayId => $_getSZ(0);
  @$pb.TagNumber(1)
  set dayId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDayId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDayId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get ml => $_getIZ(1);
  @$pb.TagNumber(2)
  set ml($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMl() => $_has(1);
  @$pb.TagNumber(2)
  void clearMl() => $_clearField(2);
}

class ResConsumptionWaterAdd extends $pb.GeneratedMessage {
  factory ResConsumptionWaterAdd({
    ConsumptionWater? water,
  }) {
    final result = ResConsumptionWaterAdd._();
    if (water != null) result.water = water;
    return result;
  }

  ResConsumptionWaterAdd._();

  factory ResConsumptionWaterAdd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResConsumptionWaterAdd()..mergeFromBuffer(data, registry);
  factory ResConsumptionWaterAdd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResConsumptionWaterAdd()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResConsumptionWaterAdd',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResConsumptionWaterAdd.$_createMessage)
    ..aOM<ConsumptionWater>(1, _omitFieldNames ? '' : 'water',
        subBuilder: ConsumptionWater.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResConsumptionWaterAdd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResConsumptionWaterAdd copyWith(
          void Function(ResConsumptionWaterAdd) updates) =>
      super.copyWith((message) => updates(message as ResConsumptionWaterAdd))
          as ResConsumptionWaterAdd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResConsumptionWaterAdd() / ResConsumptionWaterAdd.new instead')
  static ResConsumptionWaterAdd create() => ResConsumptionWaterAdd._();
  static $pb.GeneratedMessage $_createMessage() => ResConsumptionWaterAdd._();
  @$core.override
  ResConsumptionWaterAdd createEmptyInstance() => ResConsumptionWaterAdd._();
  @$core.pragma('dart2js:noInline')
  static ResConsumptionWaterAdd getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResConsumptionWaterAdd>(
          ResConsumptionWaterAdd.$_createMessage);
  static ResConsumptionWaterAdd? _defaultInstance;

  @$pb.TagNumber(1)
  ConsumptionWater get water => $_getN(0);
  @$pb.TagNumber(1)
  set water(ConsumptionWater value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasWater() => $_has(0);
  @$pb.TagNumber(1)
  void clearWater() => $_clearField(1);
  @$pb.TagNumber(1)
  ConsumptionWater ensureWater() => $_ensure(0);
}

class ReqConsumptionPrefsGet extends $pb.GeneratedMessage {
  factory ReqConsumptionPrefsGet() => ReqConsumptionPrefsGet._();

  ReqConsumptionPrefsGet._();

  factory ReqConsumptionPrefsGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqConsumptionPrefsGet()..mergeFromBuffer(data, registry);
  factory ReqConsumptionPrefsGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqConsumptionPrefsGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqConsumptionPrefsGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqConsumptionPrefsGet.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqConsumptionPrefsGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqConsumptionPrefsGet copyWith(
          void Function(ReqConsumptionPrefsGet) updates) =>
      super.copyWith((message) => updates(message as ReqConsumptionPrefsGet))
          as ReqConsumptionPrefsGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqConsumptionPrefsGet() / ReqConsumptionPrefsGet.new instead')
  static ReqConsumptionPrefsGet create() => ReqConsumptionPrefsGet._();
  static $pb.GeneratedMessage $_createMessage() => ReqConsumptionPrefsGet._();
  @$core.override
  ReqConsumptionPrefsGet createEmptyInstance() => ReqConsumptionPrefsGet._();
  @$core.pragma('dart2js:noInline')
  static ReqConsumptionPrefsGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqConsumptionPrefsGet>(
          ReqConsumptionPrefsGet.$_createMessage);
  static ReqConsumptionPrefsGet? _defaultInstance;
}

class ResConsumptionPrefsGet extends $pb.GeneratedMessage {
  factory ResConsumptionPrefsGet({
    ConsumptionPrefs? prefs,
  }) {
    final result = ResConsumptionPrefsGet._();
    if (prefs != null) result.prefs = prefs;
    return result;
  }

  ResConsumptionPrefsGet._();

  factory ResConsumptionPrefsGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResConsumptionPrefsGet()..mergeFromBuffer(data, registry);
  factory ResConsumptionPrefsGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResConsumptionPrefsGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResConsumptionPrefsGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResConsumptionPrefsGet.$_createMessage)
    ..aOM<ConsumptionPrefs>(1, _omitFieldNames ? '' : 'prefs',
        subBuilder: ConsumptionPrefs.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResConsumptionPrefsGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResConsumptionPrefsGet copyWith(
          void Function(ResConsumptionPrefsGet) updates) =>
      super.copyWith((message) => updates(message as ResConsumptionPrefsGet))
          as ResConsumptionPrefsGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResConsumptionPrefsGet() / ResConsumptionPrefsGet.new instead')
  static ResConsumptionPrefsGet create() => ResConsumptionPrefsGet._();
  static $pb.GeneratedMessage $_createMessage() => ResConsumptionPrefsGet._();
  @$core.override
  ResConsumptionPrefsGet createEmptyInstance() => ResConsumptionPrefsGet._();
  @$core.pragma('dart2js:noInline')
  static ResConsumptionPrefsGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResConsumptionPrefsGet>(
          ResConsumptionPrefsGet.$_createMessage);
  static ResConsumptionPrefsGet? _defaultInstance;

  @$pb.TagNumber(1)
  ConsumptionPrefs get prefs => $_getN(0);
  @$pb.TagNumber(1)
  set prefs(ConsumptionPrefs value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPrefs() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrefs() => $_clearField(1);
  @$pb.TagNumber(1)
  ConsumptionPrefs ensurePrefs() => $_ensure(0);
}

class ReqConsumptionPrefsPut extends $pb.GeneratedMessage {
  factory ReqConsumptionPrefsPut({
    ConsumptionPrefs? prefs,
  }) {
    final result = ReqConsumptionPrefsPut._();
    if (prefs != null) result.prefs = prefs;
    return result;
  }

  ReqConsumptionPrefsPut._();

  factory ReqConsumptionPrefsPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqConsumptionPrefsPut()..mergeFromBuffer(data, registry);
  factory ReqConsumptionPrefsPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqConsumptionPrefsPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqConsumptionPrefsPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqConsumptionPrefsPut.$_createMessage)
    ..aOM<ConsumptionPrefs>(1, _omitFieldNames ? '' : 'prefs',
        subBuilder: ConsumptionPrefs.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqConsumptionPrefsPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqConsumptionPrefsPut copyWith(
          void Function(ReqConsumptionPrefsPut) updates) =>
      super.copyWith((message) => updates(message as ReqConsumptionPrefsPut))
          as ReqConsumptionPrefsPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqConsumptionPrefsPut() / ReqConsumptionPrefsPut.new instead')
  static ReqConsumptionPrefsPut create() => ReqConsumptionPrefsPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqConsumptionPrefsPut._();
  @$core.override
  ReqConsumptionPrefsPut createEmptyInstance() => ReqConsumptionPrefsPut._();
  @$core.pragma('dart2js:noInline')
  static ReqConsumptionPrefsPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqConsumptionPrefsPut>(
          ReqConsumptionPrefsPut.$_createMessage);
  static ReqConsumptionPrefsPut? _defaultInstance;

  @$pb.TagNumber(1)
  ConsumptionPrefs get prefs => $_getN(0);
  @$pb.TagNumber(1)
  set prefs(ConsumptionPrefs value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPrefs() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrefs() => $_clearField(1);
  @$pb.TagNumber(1)
  ConsumptionPrefs ensurePrefs() => $_ensure(0);
}

class ResConsumptionPrefsPut extends $pb.GeneratedMessage {
  factory ResConsumptionPrefsPut({
    ConsumptionPrefs? prefs,
  }) {
    final result = ResConsumptionPrefsPut._();
    if (prefs != null) result.prefs = prefs;
    return result;
  }

  ResConsumptionPrefsPut._();

  factory ResConsumptionPrefsPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResConsumptionPrefsPut()..mergeFromBuffer(data, registry);
  factory ResConsumptionPrefsPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResConsumptionPrefsPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResConsumptionPrefsPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResConsumptionPrefsPut.$_createMessage)
    ..aOM<ConsumptionPrefs>(1, _omitFieldNames ? '' : 'prefs',
        subBuilder: ConsumptionPrefs.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResConsumptionPrefsPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResConsumptionPrefsPut copyWith(
          void Function(ResConsumptionPrefsPut) updates) =>
      super.copyWith((message) => updates(message as ResConsumptionPrefsPut))
          as ResConsumptionPrefsPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResConsumptionPrefsPut() / ResConsumptionPrefsPut.new instead')
  static ResConsumptionPrefsPut create() => ResConsumptionPrefsPut._();
  static $pb.GeneratedMessage $_createMessage() => ResConsumptionPrefsPut._();
  @$core.override
  ResConsumptionPrefsPut createEmptyInstance() => ResConsumptionPrefsPut._();
  @$core.pragma('dart2js:noInline')
  static ResConsumptionPrefsPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResConsumptionPrefsPut>(
          ResConsumptionPrefsPut.$_createMessage);
  static ResConsumptionPrefsPut? _defaultInstance;

  @$pb.TagNumber(1)
  ConsumptionPrefs get prefs => $_getN(0);
  @$pb.TagNumber(1)
  set prefs(ConsumptionPrefs value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPrefs() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrefs() => $_clearField(1);
  @$pb.TagNumber(1)
  ConsumptionPrefs ensurePrefs() => $_ensure(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
