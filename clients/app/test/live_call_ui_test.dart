import 'package:alienai_c35/c/live/live_call_ui.dart';
import 'package:alienai_c35/c/live/live_offer.dart';
import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final offers = liveOffersOfflineFallback();

  test('gemini composer menu has two gemini offers', () {
    const model = AgentModel(
      id: 'gemini-3.8-flash',
      chip: 'Gemini',
      label: 'Gemini 3.8 Flash',
      provider: 'google',
      providerModel: 'gemini-3.8-flash',
    );
    final menu = liveCallMenuOffers(offers, model);
    expect(menu.length, 2);
    expect(menu.every((o) => o.family == 'gemini'), isTrue);
    expect(liveCallPrimaryLabelKey(model), 'live.gemini.label');
  });

  test('claude composer uses Live Call primary and all enabled menu', () {
    const model = AgentModel(
      id: 'claude-sonnet-4-5',
      chip: 'Claude',
      label: 'Claude',
      provider: 'anthropic',
      providerModel: 'claude-sonnet-4-5',
    );
    expect(liveCallPrimaryLabelKey(model), 'home.liveCall');
    final menu = liveCallMenuOffers(offers, model);
    expect(menu.every((o) => o.enabled), isTrue);
    expect(menu.length, 3);
  });

  test('openai composer menu is openai family only', () {
    const model = AgentModel.gpt4o;
    final menu = liveCallMenuOffers(offers, model);
    expect(menu.length, 1);
    expect(menu.first.family, 'openai');
    expect(menu.first.enabled, isFalse);
    expect(liveOfferMenuLabel(menu.first), contains('Coming soon'));
  });

  test('grok composer shows coming soon on disabled offer', () {
    const model = AgentModel(
      id: 'grok-4',
      chip: 'Grok',
      label: 'Grok',
      provider: 'xai',
      providerModel: 'grok-4',
    );
    final menu = liveCallMenuOffers(offers, model);
    expect(menu.length, 1);
    expect(menu.first.enabled, isFalse);
    expect(liveOfferMenuLabel(menu.first), contains('Coming soon'));
  });
}
