import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/skill.pb.dart';

class SkillApi {
  SkillApi(this.conn);

  final ChatConn conn;

  Future<List<Skill>> list({SkillScope scope = SkillScope.SKILL_SCOPE_USER, int deviceIid = 0, int teamIid = 0}) async {
    final res = await conn.skillList(scope: scope, deviceIid: deviceIid, teamIid: teamIid);
    return res.skills;
  }

  Future<Skill> put(Skill skill) async {
    final res = await conn.skillPut(skill);
    if (!res.hasSkill()) throw 'skill put failed';
    return res.skill;
  }

  Future<List<SkillCatalog>> catalogList({String q = '', int limit = 50}) async {
    final res = await conn.skillCatalogList(q: q, limit: limit);
    return res.catalogs;
  }

  Future<Skill> catalogInstall({required int catalogId, SkillScope scope = SkillScope.SKILL_SCOPE_USER, int deviceIid = 0, int variantId = 0, int releaseId = 0}) async {
    final res = await conn.skillCatalogInstall(catalogId: catalogId, scope: scope, deviceIid: deviceIid, variantId: variantId, releaseId: releaseId);
    if (!res.hasSkill()) throw 'install failed';
    return res.skill;
  }

  Future<List<SkillCatalog>> catalogSearch({String q = '', String tagsJson = '', int limit = 20, int offset = 0}) async {
    final res = await conn.skillCatalogSearch(q: q, tagsJson: tagsJson, limit: limit, offset: offset);
    return res.catalogs;
  }

  Future<ResSkillCatalogSubmit> catalogSubmit({required int skillId, String submitAction = 'new', int existingCatalogId = 0}) async {
    return conn.skillCatalogSubmit(skillId: skillId, submitAction: submitAction, existingCatalogId: existingCatalogId);
  }

  Future<ResSkillRunReport> runReport({required int skillId, bool success = true, int stepIndex = 0, String error = ''}) async {
    return conn.skillRunReport(skillId: skillId, success: success, stepIndex: stepIndex, error: error);
  }
}

String skillCatalogPriceLabel(SkillCatalog catalog, {String currency = 'IDR'}) {
  final period = catalog.billingPeriod;
  final free = period == 'free' || (catalog.priceIdr <= 0 && catalog.priceUsd <= 0);
  if (free) return 'Free';
  final suffix = switch (period) {
    'monthly' => ' / mo',
    'yearly' => ' / yr',
    'one_time' => '',
    _ => '',
  };
  if (currency.toUpperCase() == 'IDR' && catalog.priceIdr > 0) {
    final n = catalog.priceIdr.round();
    return 'IDR ${n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}$suffix';
  }
  if (catalog.priceUsd > 0) return 'USD ${catalog.priceUsd.toStringAsFixed(2)}$suffix';
  return 'Free';
}
