import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/pb/c35/session.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/session/session_init_cache.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SessionInitCache persist and shell restore', () async {
    SharedPreferences.setMockInitialValues({});
    Session.instance.uid = 99000;
    Session.instance.token = 't';

    final init = ResSessionInit(
      serverTimeMs: Int64(1700000000000),
      billing: BillingAccount(planTier: 'trial', balanceUsd: 1.5),
      nav: NavCounts(bots: 2, devices: 3, sites: 4, mailInboxUnread: 1, mailMenuVisible: true),
      profile: IdentityProfile(name: 'Chito', alienId: 'chito', email: 'a@b.c', globalRoles: ['finance']),
      models: [
        PromptModelOption(id: 'auto', label: 'Alien AI', provider: 'alienai', isDefault: true),
        PromptModelOption(id: 'gpt-4o', label: 'GPT-4o', provider: 'openai'),
      ],
    );
    await SessionInitCache.persist(init);

    expect(await SessionInitCache.sinceMs(), 1700000000000);
    final cachedModels = await SessionInitCache.loadModels();
    expect(cachedModels.length, 2);

    AppStore.instance.billing = null;
    final store = ChatStore();
    await store.sessionInitCacheRestore();

    expect(AppStore.instance.billing?.planTier, 'trial');
    expect(store.navCounts.bots, 2);
    expect(store.models.length, greaterThan(1));

    await SessionInitCache.clearForUid(99000);
    expect(await SessionInitCache.load(), isNull);
  });

  test('session init does not collapse model catalog to server fallback', () {
    final store = ChatStore();
    store.models = [
      AgentModel.alien,
      const AgentModel(id: 'gpt-4o', chip: 'GPT-4o', label: 'GPT-4o', provider: 'openai', providerModel: 'gpt-4o'),
    ];
    store.sessionInitMerge(
      ResSessionInit(
        models: [PromptModelOption(id: 'alienai', label: 'Alien AI', provider: 'alienai', isDefault: true)],
      ),
    );
    expect(store.models.length, 2);
  });
}