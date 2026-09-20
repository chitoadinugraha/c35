//
//  Generated code. Do not modify.
//  source: c35/consumption.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'consumption.pbenum.dart';

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
  }) {
    final $result = create();
    if (calories != null) {
      $result.calories = calories;
    }
    if (protein != null) {
      $result.protein = protein;
    }
    if (fat != null) {
      $result.fat = fat;
    }
    if (carbs != null) {
      $result.carbs = carbs;
    }
    if (fiber != null) {
      $result.fiber = fiber;
    }
    if (sugar != null) {
      $result.sugar = sugar;
    }
    if (sodium != null) {
      $result.sodium = sodium;
    }
    if (potassium != null) {
      $result.potassium = potassium;
    }
    if (vitaminA != null) {
      $result.vitaminA = vitaminA;
    }
    if (vitaminC != null) {
      $result.vitaminC = vitaminC;
    }
    if (vitaminD != null) {
      $result.vitaminD = vitaminD;
    }
    if (vitaminE != null) {
      $result.vitaminE = vitaminE;
    }
    if (vitaminK != null) {
      $result.vitaminK = vitaminK;
    }
    if (calcium != null) {
      $result.calcium = calcium;
    }
    if (iron != null) {
      $result.iron = iron;
    }
    if (magnesium != null) {
      $result.magnesium = magnesium;
    }
    if (phosphorus != null) {
      $result.phosphorus = phosphorus;
    }
    if (zinc != null) {
      $result.zinc = zinc;
    }
    if (copper != null) {
      $result.copper = copper;
    }
    return $result;
  }
  Nutrition._() : super();
  factory Nutrition.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Nutrition.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Nutrition', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'calories', $pb.PbFieldType.O3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'protein', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'fat', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'carbs', $pb.PbFieldType.O3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'fiber', $pb.PbFieldType.O3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'sugar', $pb.PbFieldType.O3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'sodium', $pb.PbFieldType.O3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'potassium', $pb.PbFieldType.O3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'vitaminA', $pb.PbFieldType.O3)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'vitaminC', $pb.PbFieldType.O3)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'vitaminD', $pb.PbFieldType.O3)
    ..a<$core.int>(12, _omitFieldNames ? '' : 'vitaminE', $pb.PbFieldType.O3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'vitaminK', $pb.PbFieldType.O3)
    ..a<$core.int>(14, _omitFieldNames ? '' : 'calcium', $pb.PbFieldType.O3)
    ..a<$core.int>(15, _omitFieldNames ? '' : 'iron', $pb.PbFieldType.O3)
    ..a<$core.int>(16, _omitFieldNames ? '' : 'magnesium', $pb.PbFieldType.O3)
    ..a<$core.int>(17, _omitFieldNames ? '' : 'phosphorus', $pb.PbFieldType.O3)
    ..a<$core.int>(18, _omitFieldNames ? '' : 'zinc', $pb.PbFieldType.O3)
    ..a<$core.int>(19, _omitFieldNames ? '' : 'copper', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Nutrition clone() => Nutrition()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Nutrition copyWith(void Function(Nutrition) updates) => super.copyWith((message) => updates(message as Nutrition)) as Nutrition;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Nutrition create() => Nutrition._();
  Nutrition createEmptyInstance() => create();
  static $pb.PbList<Nutrition> createRepeated() => $pb.PbList<Nutrition>();
  @$core.pragma('dart2js:noInline')
  static Nutrition getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Nutrition>(create);
  static Nutrition? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get calories => $_getIZ(0);
  @$pb.TagNumber(1)
  set calories($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCalories() => $_has(0);
  @$pb.TagNumber(1)
  void clearCalories() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get protein => $_getIZ(1);
  @$pb.TagNumber(2)
  set protein($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasProtein() => $_has(1);
  @$pb.TagNumber(2)
  void clearProtein() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get fat => $_getIZ(2);
  @$pb.TagNumber(3)
  set fat($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasFat() => $_has(2);
  @$pb.TagNumber(3)
  void clearFat() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get carbs => $_getIZ(3);
  @$pb.TagNumber(4)
  set carbs($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCarbs() => $_has(3);
  @$pb.TagNumber(4)
  void clearCarbs() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get fiber => $_getIZ(4);
  @$pb.TagNumber(5)
  set fiber($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasFiber() => $_has(4);
  @$pb.TagNumber(5)
  void clearFiber() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get sugar => $_getIZ(5);
  @$pb.TagNumber(6)
  set sugar($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasSugar() => $_has(5);
  @$pb.TagNumber(6)
  void clearSugar() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get sodium => $_getIZ(6);
  @$pb.TagNumber(7)
  set sodium($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasSodium() => $_has(6);
  @$pb.TagNumber(7)
  void clearSodium() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get potassium => $_getIZ(7);
  @$pb.TagNumber(8)
  set potassium($core.int v) { $_setSignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasPotassium() => $_has(7);
  @$pb.TagNumber(8)
  void clearPotassium() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get vitaminA => $_getIZ(8);
  @$pb.TagNumber(9)
  set vitaminA($core.int v) { $_setSignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasVitaminA() => $_has(8);
  @$pb.TagNumber(9)
  void clearVitaminA() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get vitaminC => $_getIZ(9);
  @$pb.TagNumber(10)
  set vitaminC($core.int v) { $_setSignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasVitaminC() => $_has(9);
  @$pb.TagNumber(10)
  void clearVitaminC() => clearField(10);

  @$pb.TagNumber(11)
  $core.int get vitaminD => $_getIZ(10);
  @$pb.TagNumber(11)
  set vitaminD($core.int v) { $_setSignedInt32(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasVitaminD() => $_has(10);
  @$pb.TagNumber(11)
  void clearVitaminD() => clearField(11);

  @$pb.TagNumber(12)
  $core.int get vitaminE => $_getIZ(11);
  @$pb.TagNumber(12)
  set vitaminE($core.int v) { $_setSignedInt32(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasVitaminE() => $_has(11);
  @$pb.TagNumber(12)
  void clearVitaminE() => clearField(12);

  @$pb.TagNumber(13)
  $core.int get vitaminK => $_getIZ(12);
  @$pb.TagNumber(13)
  set vitaminK($core.int v) { $_setSignedInt32(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasVitaminK() => $_has(12);
  @$pb.TagNumber(13)
  void clearVitaminK() => clearField(13);

  @$pb.TagNumber(14)
  $core.int get calcium => $_getIZ(13);
  @$pb.TagNumber(14)
  set calcium($core.int v) { $_setSignedInt32(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasCalcium() => $_has(13);
  @$pb.TagNumber(14)
  void clearCalcium() => clearField(14);

  @$pb.TagNumber(15)
  $core.int get iron => $_getIZ(14);
  @$pb.TagNumber(15)
  set iron($core.int v) { $_setSignedInt32(14, v); }
  @$pb.TagNumber(15)
  $core.bool hasIron() => $_has(14);
  @$pb.TagNumber(15)
  void clearIron() => clearField(15);

  @$pb.TagNumber(16)
  $core.int get magnesium => $_getIZ(15);
  @$pb.TagNumber(16)
  set magnesium($core.int v) { $_setSignedInt32(15, v); }
  @$pb.TagNumber(16)
  $core.bool hasMagnesium() => $_has(15);
  @$pb.TagNumber(16)
  void clearMagnesium() => clearField(16);

  @$pb.TagNumber(17)
  $core.int get phosphorus => $_getIZ(16);
  @$pb.TagNumber(17)
  set phosphorus($core.int v) { $_setSignedInt32(16, v); }
  @$pb.TagNumber(17)
  $core.bool hasPhosphorus() => $_has(16);
  @$pb.TagNumber(17)
  void clearPhosphorus() => clearField(17);

  @$pb.TagNumber(18)
  $core.int get zinc => $_getIZ(17);
  @$pb.TagNumber(18)
  set zinc($core.int v) { $_setSignedInt32(17, v); }
  @$pb.TagNumber(18)
  $core.bool hasZinc() => $_has(17);
  @$pb.TagNumber(18)
  void clearZinc() => clearField(18);

  @$pb.TagNumber(19)
  $core.int get copper => $_getIZ(18);
  @$pb.TagNumber(19)
  set copper($core.int v) { $_setSignedInt32(18, v); }
  @$pb.TagNumber(19)
  $core.bool hasCopper() => $_has(18);
  @$pb.TagNumber(19)
  void clearCopper() => clearField(19);
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
    final $result = create();
    if (idx != null) {
      $result.idx = idx;
    }
    if (name != null) {
      $result.name = name;
    }
    if (nameId != null) {
      $result.nameId = nameId;
    }
    if (qty != null) {
      $result.qty = qty;
    }
    if (pic != null) {
      $result.pic = pic;
    }
    if (nutrition != null) {
      $result.nutrition = nutrition;
    }
    return $result;
  }
  ConsumptionItem._() : super();
  factory ConsumptionItem.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ConsumptionItem.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ConsumptionItem', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'idx', $pb.PbFieldType.O3)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'nameId')
    ..a<$core.double>(4, _omitFieldNames ? '' : 'qty', $pb.PbFieldType.OF)
    ..aOS(5, _omitFieldNames ? '' : 'pic')
    ..aOM<Nutrition>(6, _omitFieldNames ? '' : 'nutrition', subBuilder: Nutrition.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ConsumptionItem clone() => ConsumptionItem()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ConsumptionItem copyWith(void Function(ConsumptionItem) updates) => super.copyWith((message) => updates(message as ConsumptionItem)) as ConsumptionItem;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConsumptionItem create() => ConsumptionItem._();
  ConsumptionItem createEmptyInstance() => create();
  static $pb.PbList<ConsumptionItem> createRepeated() => $pb.PbList<ConsumptionItem>();
  @$core.pragma('dart2js:noInline')
  static ConsumptionItem getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConsumptionItem>(create);
  static ConsumptionItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get idx => $_getIZ(0);
  @$pb.TagNumber(1)
  set idx($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIdx() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdx() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get nameId => $_getSZ(2);
  @$pb.TagNumber(3)
  set nameId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasNameId() => $_has(2);
  @$pb.TagNumber(3)
  void clearNameId() => clearField(3);

  @$pb.TagNumber(4)
  $core.double get qty => $_getN(3);
  @$pb.TagNumber(4)
  set qty($core.double v) { $_setFloat(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasQty() => $_has(3);
  @$pb.TagNumber(4)
  void clearQty() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get pic => $_getSZ(4);
  @$pb.TagNumber(5)
  set pic($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPic() => $_has(4);
  @$pb.TagNumber(5)
  void clearPic() => clearField(5);

  @$pb.TagNumber(6)
  Nutrition get nutrition => $_getN(5);
  @$pb.TagNumber(6)
  set nutrition(Nutrition v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasNutrition() => $_has(5);
  @$pb.TagNumber(6)
  void clearNutrition() => clearField(6);
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
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (ownerIid != null) {
      $result.ownerIid = ownerIid;
    }
    if (note != null) {
      $result.note = note;
    }
    if (photoHash != null) {
      $result.photoHash = photoHash;
    }
    if (mealFingerprint != null) {
      $result.mealFingerprint = mealFingerprint;
    }
    if (mealType != null) {
      $result.mealType = mealType;
    }
    if (pics != null) {
      $result.pics.addAll(pics);
    }
    if (loggedTsMs != null) {
      $result.loggedTsMs = loggedTsMs;
    }
    if (isArchived != null) {
      $result.isArchived = isArchived;
    }
    if (items != null) {
      $result.items.addAll(items);
    }
    if (createdTsMs != null) {
      $result.createdTsMs = createdTsMs;
    }
    if (updatedTsMs != null) {
      $result.updatedTsMs = updatedTsMs;
    }
    if (deletedTsMs != null) {
      $result.deletedTsMs = deletedTsMs;
    }
    return $result;
  }
  Consumption._() : super();
  factory Consumption.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Consumption.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Consumption', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(3, _omitFieldNames ? '' : 'note')
    ..aOS(4, _omitFieldNames ? '' : 'photoHash')
    ..aOS(5, _omitFieldNames ? '' : 'mealFingerprint')
    ..e<ConsumeMealType>(6, _omitFieldNames ? '' : 'mealType', $pb.PbFieldType.OE, defaultOrMaker: ConsumeMealType.CONSUME_MEAL_TYPE_OTHER, valueOf: ConsumeMealType.valueOf, enumValues: ConsumeMealType.values)
    ..pPS(7, _omitFieldNames ? '' : 'pics')
    ..aInt64(8, _omitFieldNames ? '' : 'loggedTsMs')
    ..aOB(9, _omitFieldNames ? '' : 'isArchived')
    ..pc<ConsumptionItem>(10, _omitFieldNames ? '' : 'items', $pb.PbFieldType.PM, subBuilder: ConsumptionItem.create)
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Consumption clone() => Consumption()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Consumption copyWith(void Function(Consumption) updates) => super.copyWith((message) => updates(message as Consumption)) as Consumption;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Consumption create() => Consumption._();
  Consumption createEmptyInstance() => create();
  static $pb.PbList<Consumption> createRepeated() => $pb.PbList<Consumption>();
  @$core.pragma('dart2js:noInline')
  static Consumption getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Consumption>(create);
  static Consumption? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get note => $_getSZ(2);
  @$pb.TagNumber(3)
  set note($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasNote() => $_has(2);
  @$pb.TagNumber(3)
  void clearNote() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get photoHash => $_getSZ(3);
  @$pb.TagNumber(4)
  set photoHash($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPhotoHash() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhotoHash() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get mealFingerprint => $_getSZ(4);
  @$pb.TagNumber(5)
  set mealFingerprint($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasMealFingerprint() => $_has(4);
  @$pb.TagNumber(5)
  void clearMealFingerprint() => clearField(5);

  @$pb.TagNumber(6)
  ConsumeMealType get mealType => $_getN(5);
  @$pb.TagNumber(6)
  set mealType(ConsumeMealType v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasMealType() => $_has(5);
  @$pb.TagNumber(6)
  void clearMealType() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.String> get pics => $_getList(6);

  @$pb.TagNumber(8)
  $fixnum.Int64 get loggedTsMs => $_getI64(7);
  @$pb.TagNumber(8)
  set loggedTsMs($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasLoggedTsMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearLoggedTsMs() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get isArchived => $_getBF(8);
  @$pb.TagNumber(9)
  set isArchived($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasIsArchived() => $_has(8);
  @$pb.TagNumber(9)
  void clearIsArchived() => clearField(9);

  @$pb.TagNumber(10)
  $core.List<ConsumptionItem> get items => $_getList(9);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(10);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(10, v); }
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(10);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(11);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(11, v); }
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(11);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(12);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(12, v); }
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(12);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => clearField(22);
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
    final $result = create();
    if (ownerIid != null) {
      $result.ownerIid = ownerIid;
    }
    if (dayId != null) {
      $result.dayId = dayId;
    }
    if (ml != null) {
      $result.ml = ml;
    }
    if (goalMl != null) {
      $result.goalMl = goalMl;
    }
    if (entryCount != null) {
      $result.entryCount = entryCount;
    }
    if (createdTsMs != null) {
      $result.createdTsMs = createdTsMs;
    }
    if (updatedTsMs != null) {
      $result.updatedTsMs = updatedTsMs;
    }
    if (deletedTsMs != null) {
      $result.deletedTsMs = deletedTsMs;
    }
    return $result;
  }
  ConsumptionWater._() : super();
  factory ConsumptionWater.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ConsumptionWater.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ConsumptionWater', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(2, _omitFieldNames ? '' : 'dayId')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'ml', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'goalMl', $pb.PbFieldType.O3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'entryCount', $pb.PbFieldType.O3)
    ..aInt64(10, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(11, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(12, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ConsumptionWater clone() => ConsumptionWater()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ConsumptionWater copyWith(void Function(ConsumptionWater) updates) => super.copyWith((message) => updates(message as ConsumptionWater)) as ConsumptionWater;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConsumptionWater create() => ConsumptionWater._();
  ConsumptionWater createEmptyInstance() => create();
  static $pb.PbList<ConsumptionWater> createRepeated() => $pb.PbList<ConsumptionWater>();
  @$core.pragma('dart2js:noInline')
  static ConsumptionWater getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConsumptionWater>(create);
  static ConsumptionWater? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get ownerIid => $_getI64(0);
  @$pb.TagNumber(1)
  set ownerIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOwnerIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearOwnerIid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get dayId => $_getSZ(1);
  @$pb.TagNumber(2)
  set dayId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDayId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDayId() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get ml => $_getIZ(2);
  @$pb.TagNumber(3)
  set ml($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMl() => $_has(2);
  @$pb.TagNumber(3)
  void clearMl() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get goalMl => $_getIZ(3);
  @$pb.TagNumber(4)
  set goalMl($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasGoalMl() => $_has(3);
  @$pb.TagNumber(4)
  void clearGoalMl() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get entryCount => $_getIZ(4);
  @$pb.TagNumber(5)
  set entryCount($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasEntryCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearEntryCount() => clearField(5);

  @$pb.TagNumber(10)
  $fixnum.Int64 get createdTsMs => $_getI64(5);
  @$pb.TagNumber(10)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(10)
  $core.bool hasCreatedTsMs() => $_has(5);
  @$pb.TagNumber(10)
  void clearCreatedTsMs() => clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get updatedTsMs => $_getI64(6);
  @$pb.TagNumber(11)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(11)
  $core.bool hasUpdatedTsMs() => $_has(6);
  @$pb.TagNumber(11)
  void clearUpdatedTsMs() => clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get deletedTsMs => $_getI64(7);
  @$pb.TagNumber(12)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(12)
  $core.bool hasDeletedTsMs() => $_has(7);
  @$pb.TagNumber(12)
  void clearDeletedTsMs() => clearField(12);
}

class ConsumptionPrefs extends $pb.GeneratedMessage {
  factory ConsumptionPrefs({
    $fixnum.Int64? ownerIid,
    $core.int? calorieGoalKcal,
    $core.int? waterGoalMl,
    $fixnum.Int64? updatedTsMs,
  }) {
    final $result = create();
    if (ownerIid != null) {
      $result.ownerIid = ownerIid;
    }
    if (calorieGoalKcal != null) {
      $result.calorieGoalKcal = calorieGoalKcal;
    }
    if (waterGoalMl != null) {
      $result.waterGoalMl = waterGoalMl;
    }
    if (updatedTsMs != null) {
      $result.updatedTsMs = updatedTsMs;
    }
    return $result;
  }
  ConsumptionPrefs._() : super();
  factory ConsumptionPrefs.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ConsumptionPrefs.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ConsumptionPrefs', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'ownerIid')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'calorieGoalKcal', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'waterGoalMl', $pb.PbFieldType.O3)
    ..aInt64(4, _omitFieldNames ? '' : 'updatedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ConsumptionPrefs clone() => ConsumptionPrefs()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ConsumptionPrefs copyWith(void Function(ConsumptionPrefs) updates) => super.copyWith((message) => updates(message as ConsumptionPrefs)) as ConsumptionPrefs;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConsumptionPrefs create() => ConsumptionPrefs._();
  ConsumptionPrefs createEmptyInstance() => create();
  static $pb.PbList<ConsumptionPrefs> createRepeated() => $pb.PbList<ConsumptionPrefs>();
  @$core.pragma('dart2js:noInline')
  static ConsumptionPrefs getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConsumptionPrefs>(create);
  static ConsumptionPrefs? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get ownerIid => $_getI64(0);
  @$pb.TagNumber(1)
  set ownerIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOwnerIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearOwnerIid() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get calorieGoalKcal => $_getIZ(1);
  @$pb.TagNumber(2)
  set calorieGoalKcal($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCalorieGoalKcal() => $_has(1);
  @$pb.TagNumber(2)
  void clearCalorieGoalKcal() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get waterGoalMl => $_getIZ(2);
  @$pb.TagNumber(3)
  set waterGoalMl($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasWaterGoalMl() => $_has(2);
  @$pb.TagNumber(3)
  void clearWaterGoalMl() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get updatedTsMs => $_getI64(3);
  @$pb.TagNumber(4)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasUpdatedTsMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpdatedTsMs() => clearField(4);
}

class ReqConsumptionList extends $pb.GeneratedMessage {
  factory ReqConsumptionList({
    $core.String? dayId,
    $fixnum.Int64? afterId,
    $core.int? limit,
  }) {
    final $result = create();
    if (dayId != null) {
      $result.dayId = dayId;
    }
    if (afterId != null) {
      $result.afterId = afterId;
    }
    if (limit != null) {
      $result.limit = limit;
    }
    return $result;
  }
  ReqConsumptionList._() : super();
  factory ReqConsumptionList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqConsumptionList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqConsumptionList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'dayId')
    ..aInt64(2, _omitFieldNames ? '' : 'afterId')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqConsumptionList clone() => ReqConsumptionList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqConsumptionList copyWith(void Function(ReqConsumptionList) updates) => super.copyWith((message) => updates(message as ReqConsumptionList)) as ReqConsumptionList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqConsumptionList create() => ReqConsumptionList._();
  ReqConsumptionList createEmptyInstance() => create();
  static $pb.PbList<ReqConsumptionList> createRepeated() => $pb.PbList<ReqConsumptionList>();
  @$core.pragma('dart2js:noInline')
  static ReqConsumptionList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqConsumptionList>(create);
  static ReqConsumptionList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get dayId => $_getSZ(0);
  @$pb.TagNumber(1)
  set dayId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDayId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDayId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get afterId => $_getI64(1);
  @$pb.TagNumber(2)
  set afterId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAfterId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAfterId() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => clearField(3);
}

class ResConsumptionList extends $pb.GeneratedMessage {
  factory ResConsumptionList({
    $core.Iterable<Consumption>? consumptions,
  }) {
    final $result = create();
    if (consumptions != null) {
      $result.consumptions.addAll(consumptions);
    }
    return $result;
  }
  ResConsumptionList._() : super();
  factory ResConsumptionList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResConsumptionList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResConsumptionList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pc<Consumption>(1, _omitFieldNames ? '' : 'consumptions', $pb.PbFieldType.PM, subBuilder: Consumption.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResConsumptionList clone() => ResConsumptionList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResConsumptionList copyWith(void Function(ResConsumptionList) updates) => super.copyWith((message) => updates(message as ResConsumptionList)) as ResConsumptionList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResConsumptionList create() => ResConsumptionList._();
  ResConsumptionList createEmptyInstance() => create();
  static $pb.PbList<ResConsumptionList> createRepeated() => $pb.PbList<ResConsumptionList>();
  @$core.pragma('dart2js:noInline')
  static ResConsumptionList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResConsumptionList>(create);
  static ResConsumptionList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Consumption> get consumptions => $_getList(0);
}

class ReqConsumptionPut extends $pb.GeneratedMessage {
  factory ReqConsumptionPut({
    Consumption? consumption,
  }) {
    final $result = create();
    if (consumption != null) {
      $result.consumption = consumption;
    }
    return $result;
  }
  ReqConsumptionPut._() : super();
  factory ReqConsumptionPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqConsumptionPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqConsumptionPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Consumption>(1, _omitFieldNames ? '' : 'consumption', subBuilder: Consumption.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqConsumptionPut clone() => ReqConsumptionPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqConsumptionPut copyWith(void Function(ReqConsumptionPut) updates) => super.copyWith((message) => updates(message as ReqConsumptionPut)) as ReqConsumptionPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqConsumptionPut create() => ReqConsumptionPut._();
  ReqConsumptionPut createEmptyInstance() => create();
  static $pb.PbList<ReqConsumptionPut> createRepeated() => $pb.PbList<ReqConsumptionPut>();
  @$core.pragma('dart2js:noInline')
  static ReqConsumptionPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqConsumptionPut>(create);
  static ReqConsumptionPut? _defaultInstance;

  @$pb.TagNumber(1)
  Consumption get consumption => $_getN(0);
  @$pb.TagNumber(1)
  set consumption(Consumption v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasConsumption() => $_has(0);
  @$pb.TagNumber(1)
  void clearConsumption() => clearField(1);
  @$pb.TagNumber(1)
  Consumption ensureConsumption() => $_ensure(0);
}

class ResConsumptionPut extends $pb.GeneratedMessage {
  factory ResConsumptionPut({
    Consumption? consumption,
  }) {
    final $result = create();
    if (consumption != null) {
      $result.consumption = consumption;
    }
    return $result;
  }
  ResConsumptionPut._() : super();
  factory ResConsumptionPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResConsumptionPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResConsumptionPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Consumption>(1, _omitFieldNames ? '' : 'consumption', subBuilder: Consumption.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResConsumptionPut clone() => ResConsumptionPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResConsumptionPut copyWith(void Function(ResConsumptionPut) updates) => super.copyWith((message) => updates(message as ResConsumptionPut)) as ResConsumptionPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResConsumptionPut create() => ResConsumptionPut._();
  ResConsumptionPut createEmptyInstance() => create();
  static $pb.PbList<ResConsumptionPut> createRepeated() => $pb.PbList<ResConsumptionPut>();
  @$core.pragma('dart2js:noInline')
  static ResConsumptionPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResConsumptionPut>(create);
  static ResConsumptionPut? _defaultInstance;

  @$pb.TagNumber(1)
  Consumption get consumption => $_getN(0);
  @$pb.TagNumber(1)
  set consumption(Consumption v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasConsumption() => $_has(0);
  @$pb.TagNumber(1)
  void clearConsumption() => clearField(1);
  @$pb.TagNumber(1)
  Consumption ensureConsumption() => $_ensure(0);
}

class ReqConsumptionWaterGet extends $pb.GeneratedMessage {
  factory ReqConsumptionWaterGet({
    $core.String? dayId,
  }) {
    final $result = create();
    if (dayId != null) {
      $result.dayId = dayId;
    }
    return $result;
  }
  ReqConsumptionWaterGet._() : super();
  factory ReqConsumptionWaterGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqConsumptionWaterGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqConsumptionWaterGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'dayId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqConsumptionWaterGet clone() => ReqConsumptionWaterGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqConsumptionWaterGet copyWith(void Function(ReqConsumptionWaterGet) updates) => super.copyWith((message) => updates(message as ReqConsumptionWaterGet)) as ReqConsumptionWaterGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqConsumptionWaterGet create() => ReqConsumptionWaterGet._();
  ReqConsumptionWaterGet createEmptyInstance() => create();
  static $pb.PbList<ReqConsumptionWaterGet> createRepeated() => $pb.PbList<ReqConsumptionWaterGet>();
  @$core.pragma('dart2js:noInline')
  static ReqConsumptionWaterGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqConsumptionWaterGet>(create);
  static ReqConsumptionWaterGet? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get dayId => $_getSZ(0);
  @$pb.TagNumber(1)
  set dayId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDayId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDayId() => clearField(1);
}

class ResConsumptionWaterGet extends $pb.GeneratedMessage {
  factory ResConsumptionWaterGet({
    ConsumptionWater? water,
  }) {
    final $result = create();
    if (water != null) {
      $result.water = water;
    }
    return $result;
  }
  ResConsumptionWaterGet._() : super();
  factory ResConsumptionWaterGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResConsumptionWaterGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResConsumptionWaterGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<ConsumptionWater>(1, _omitFieldNames ? '' : 'water', subBuilder: ConsumptionWater.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResConsumptionWaterGet clone() => ResConsumptionWaterGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResConsumptionWaterGet copyWith(void Function(ResConsumptionWaterGet) updates) => super.copyWith((message) => updates(message as ResConsumptionWaterGet)) as ResConsumptionWaterGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResConsumptionWaterGet create() => ResConsumptionWaterGet._();
  ResConsumptionWaterGet createEmptyInstance() => create();
  static $pb.PbList<ResConsumptionWaterGet> createRepeated() => $pb.PbList<ResConsumptionWaterGet>();
  @$core.pragma('dart2js:noInline')
  static ResConsumptionWaterGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResConsumptionWaterGet>(create);
  static ResConsumptionWaterGet? _defaultInstance;

  @$pb.TagNumber(1)
  ConsumptionWater get water => $_getN(0);
  @$pb.TagNumber(1)
  set water(ConsumptionWater v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasWater() => $_has(0);
  @$pb.TagNumber(1)
  void clearWater() => clearField(1);
  @$pb.TagNumber(1)
  ConsumptionWater ensureWater() => $_ensure(0);
}

class ReqConsumptionWaterAdd extends $pb.GeneratedMessage {
  factory ReqConsumptionWaterAdd({
    $core.String? dayId,
    $core.int? ml,
  }) {
    final $result = create();
    if (dayId != null) {
      $result.dayId = dayId;
    }
    if (ml != null) {
      $result.ml = ml;
    }
    return $result;
  }
  ReqConsumptionWaterAdd._() : super();
  factory ReqConsumptionWaterAdd.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqConsumptionWaterAdd.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqConsumptionWaterAdd', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'dayId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'ml', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqConsumptionWaterAdd clone() => ReqConsumptionWaterAdd()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqConsumptionWaterAdd copyWith(void Function(ReqConsumptionWaterAdd) updates) => super.copyWith((message) => updates(message as ReqConsumptionWaterAdd)) as ReqConsumptionWaterAdd;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqConsumptionWaterAdd create() => ReqConsumptionWaterAdd._();
  ReqConsumptionWaterAdd createEmptyInstance() => create();
  static $pb.PbList<ReqConsumptionWaterAdd> createRepeated() => $pb.PbList<ReqConsumptionWaterAdd>();
  @$core.pragma('dart2js:noInline')
  static ReqConsumptionWaterAdd getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqConsumptionWaterAdd>(create);
  static ReqConsumptionWaterAdd? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get dayId => $_getSZ(0);
  @$pb.TagNumber(1)
  set dayId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDayId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDayId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get ml => $_getIZ(1);
  @$pb.TagNumber(2)
  set ml($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMl() => $_has(1);
  @$pb.TagNumber(2)
  void clearMl() => clearField(2);
}

class ResConsumptionWaterAdd extends $pb.GeneratedMessage {
  factory ResConsumptionWaterAdd({
    ConsumptionWater? water,
  }) {
    final $result = create();
    if (water != null) {
      $result.water = water;
    }
    return $result;
  }
  ResConsumptionWaterAdd._() : super();
  factory ResConsumptionWaterAdd.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResConsumptionWaterAdd.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResConsumptionWaterAdd', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<ConsumptionWater>(1, _omitFieldNames ? '' : 'water', subBuilder: ConsumptionWater.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResConsumptionWaterAdd clone() => ResConsumptionWaterAdd()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResConsumptionWaterAdd copyWith(void Function(ResConsumptionWaterAdd) updates) => super.copyWith((message) => updates(message as ResConsumptionWaterAdd)) as ResConsumptionWaterAdd;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResConsumptionWaterAdd create() => ResConsumptionWaterAdd._();
  ResConsumptionWaterAdd createEmptyInstance() => create();
  static $pb.PbList<ResConsumptionWaterAdd> createRepeated() => $pb.PbList<ResConsumptionWaterAdd>();
  @$core.pragma('dart2js:noInline')
  static ResConsumptionWaterAdd getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResConsumptionWaterAdd>(create);
  static ResConsumptionWaterAdd? _defaultInstance;

  @$pb.TagNumber(1)
  ConsumptionWater get water => $_getN(0);
  @$pb.TagNumber(1)
  set water(ConsumptionWater v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasWater() => $_has(0);
  @$pb.TagNumber(1)
  void clearWater() => clearField(1);
  @$pb.TagNumber(1)
  ConsumptionWater ensureWater() => $_ensure(0);
}

class ReqConsumptionPrefsGet extends $pb.GeneratedMessage {
  factory ReqConsumptionPrefsGet() => create();
  ReqConsumptionPrefsGet._() : super();
  factory ReqConsumptionPrefsGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqConsumptionPrefsGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqConsumptionPrefsGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqConsumptionPrefsGet clone() => ReqConsumptionPrefsGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqConsumptionPrefsGet copyWith(void Function(ReqConsumptionPrefsGet) updates) => super.copyWith((message) => updates(message as ReqConsumptionPrefsGet)) as ReqConsumptionPrefsGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqConsumptionPrefsGet create() => ReqConsumptionPrefsGet._();
  ReqConsumptionPrefsGet createEmptyInstance() => create();
  static $pb.PbList<ReqConsumptionPrefsGet> createRepeated() => $pb.PbList<ReqConsumptionPrefsGet>();
  @$core.pragma('dart2js:noInline')
  static ReqConsumptionPrefsGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqConsumptionPrefsGet>(create);
  static ReqConsumptionPrefsGet? _defaultInstance;
}

class ResConsumptionPrefsGet extends $pb.GeneratedMessage {
  factory ResConsumptionPrefsGet({
    ConsumptionPrefs? prefs,
  }) {
    final $result = create();
    if (prefs != null) {
      $result.prefs = prefs;
    }
    return $result;
  }
  ResConsumptionPrefsGet._() : super();
  factory ResConsumptionPrefsGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResConsumptionPrefsGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResConsumptionPrefsGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<ConsumptionPrefs>(1, _omitFieldNames ? '' : 'prefs', subBuilder: ConsumptionPrefs.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResConsumptionPrefsGet clone() => ResConsumptionPrefsGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResConsumptionPrefsGet copyWith(void Function(ResConsumptionPrefsGet) updates) => super.copyWith((message) => updates(message as ResConsumptionPrefsGet)) as ResConsumptionPrefsGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResConsumptionPrefsGet create() => ResConsumptionPrefsGet._();
  ResConsumptionPrefsGet createEmptyInstance() => create();
  static $pb.PbList<ResConsumptionPrefsGet> createRepeated() => $pb.PbList<ResConsumptionPrefsGet>();
  @$core.pragma('dart2js:noInline')
  static ResConsumptionPrefsGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResConsumptionPrefsGet>(create);
  static ResConsumptionPrefsGet? _defaultInstance;

  @$pb.TagNumber(1)
  ConsumptionPrefs get prefs => $_getN(0);
  @$pb.TagNumber(1)
  set prefs(ConsumptionPrefs v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasPrefs() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrefs() => clearField(1);
  @$pb.TagNumber(1)
  ConsumptionPrefs ensurePrefs() => $_ensure(0);
}

class ReqConsumptionPrefsPut extends $pb.GeneratedMessage {
  factory ReqConsumptionPrefsPut({
    ConsumptionPrefs? prefs,
  }) {
    final $result = create();
    if (prefs != null) {
      $result.prefs = prefs;
    }
    return $result;
  }
  ReqConsumptionPrefsPut._() : super();
  factory ReqConsumptionPrefsPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqConsumptionPrefsPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqConsumptionPrefsPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<ConsumptionPrefs>(1, _omitFieldNames ? '' : 'prefs', subBuilder: ConsumptionPrefs.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqConsumptionPrefsPut clone() => ReqConsumptionPrefsPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqConsumptionPrefsPut copyWith(void Function(ReqConsumptionPrefsPut) updates) => super.copyWith((message) => updates(message as ReqConsumptionPrefsPut)) as ReqConsumptionPrefsPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqConsumptionPrefsPut create() => ReqConsumptionPrefsPut._();
  ReqConsumptionPrefsPut createEmptyInstance() => create();
  static $pb.PbList<ReqConsumptionPrefsPut> createRepeated() => $pb.PbList<ReqConsumptionPrefsPut>();
  @$core.pragma('dart2js:noInline')
  static ReqConsumptionPrefsPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqConsumptionPrefsPut>(create);
  static ReqConsumptionPrefsPut? _defaultInstance;

  @$pb.TagNumber(1)
  ConsumptionPrefs get prefs => $_getN(0);
  @$pb.TagNumber(1)
  set prefs(ConsumptionPrefs v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasPrefs() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrefs() => clearField(1);
  @$pb.TagNumber(1)
  ConsumptionPrefs ensurePrefs() => $_ensure(0);
}

class ResConsumptionPrefsPut extends $pb.GeneratedMessage {
  factory ResConsumptionPrefsPut({
    ConsumptionPrefs? prefs,
  }) {
    final $result = create();
    if (prefs != null) {
      $result.prefs = prefs;
    }
    return $result;
  }
  ResConsumptionPrefsPut._() : super();
  factory ResConsumptionPrefsPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResConsumptionPrefsPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResConsumptionPrefsPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<ConsumptionPrefs>(1, _omitFieldNames ? '' : 'prefs', subBuilder: ConsumptionPrefs.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResConsumptionPrefsPut clone() => ResConsumptionPrefsPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResConsumptionPrefsPut copyWith(void Function(ResConsumptionPrefsPut) updates) => super.copyWith((message) => updates(message as ResConsumptionPrefsPut)) as ResConsumptionPrefsPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResConsumptionPrefsPut create() => ResConsumptionPrefsPut._();
  ResConsumptionPrefsPut createEmptyInstance() => create();
  static $pb.PbList<ResConsumptionPrefsPut> createRepeated() => $pb.PbList<ResConsumptionPrefsPut>();
  @$core.pragma('dart2js:noInline')
  static ResConsumptionPrefsPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResConsumptionPrefsPut>(create);
  static ResConsumptionPrefsPut? _defaultInstance;

  @$pb.TagNumber(1)
  ConsumptionPrefs get prefs => $_getN(0);
  @$pb.TagNumber(1)
  set prefs(ConsumptionPrefs v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasPrefs() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrefs() => clearField(1);
  @$pb.TagNumber(1)
  ConsumptionPrefs ensurePrefs() => $_ensure(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
