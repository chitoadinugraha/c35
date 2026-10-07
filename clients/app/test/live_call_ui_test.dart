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
    expect(liveCallChipUsesGenericLabel(model, offers), isFalse);
  });

  test('claude composer uses generic chip label and all enabled menu', () {
    const model = AgentModel(
      id: 'claude-sonnet-4-5',
      chip: 'Claude',
      label: 'Claude',
      provider: 'anthropic',
      providerModel: 'claude-sonnet-4-5',
    );
    expect(liveCallChipUsesGenericLabel(model, offers), isTrue);
    expect(liveCallGenericChipTitle(), 'Call AI');
    final menu = liveCallMenuOffers(offers, model);
    expect(menu.every((o) => o.enabled), isTrue);
    expect(menu.length, offers.where((o) => o.enabled).length);
  });

  test('liveCallChipCompactTitle drops call verb', () {
    expect(liveCallChipCompactTitle(), 'AI');
  });

  test('liveCallChipTitle matches welcome chip for alienai composer', () {
    const model = AgentModel(
      id: 'alienai',
      chip: 'Alien',
      label: 'Alien AI',
      provider: 'alienai',
      providerModel: 'alienai',
    );
    expect(liveCallChipTitle(model, offers), 'Call Alien AI');
  });

  test('live offer action title uses call verb and brand', () {
    final alien = offers.firstWhere((o) => o.id == 'live.alienai');
    expect(liveOfferActionTitle(alien), 'Call Alien AI');
    expect(liveOfferMenuLabel(offers.firstWhere((o) => o.id == 'live.chatgpt')), contains('Call ChatGPT'));
  });

  test('live offer brand strips legacy Call prefix from catalog text', () {
    final alien = offers.firstWhere((o) => o.id == 'live.alienai');
    expect(liveOfferBrandLabel(alien), 'Alien AI');
    final legacy = alien.clone()
      ..labelKey = ''
      ..label = 'Call Alien AI';
    expect(liveOfferBrandLabel(legacy), 'Alien AI');
    expect(liveOfferActionTitle(legacy), 'Call Alien AI');
  });

  test('openai composer opens generic menu when family offer disabled', () {
    final disabled = offers.map((o) => o.family == 'openai' ? (o.clone()..enabled = false) : o).toList();
    const model = AgentModel.gpt4o;
    expect(liveCallChipUsesGenericLabel(model, disabled), isTrue);
    final menu = liveCallMenuOffers(disabled, model);
    expect(menu.length, disabled.where((o) => o.enabled).length);
    expect(menu.every((o) => o.enabled), isTrue);
    expect(liveCallGenericChipTitle(), 'Call AI');
  });

  test('grok composer opens generic menu when family offer disabled', () {
    final disabled = offers.map((o) => o.family == 'xai' ? (o.clone()..enabled = false) : o).toList();
    const model = AgentModel(
      id: 'grok-4',
      chip: 'Grok',
      label: 'Grok',
      provider: 'xai',
      providerModel: 'grok-4',
    );
    expect(liveCallChipUsesGenericLabel(model, disabled), isTrue);
    final menu = liveCallMenuOffers(disabled, model);
    expect(menu.length, disabled.where((o) => o.enabled).length);
    expect(menu.every((o) => o.enabled), isTrue);
  });

  test('offline fallback offers include retailVideoUsdPerMin for all models', () {
    final alien = offers.firstWhere((o) => o.id == 'live.alienai');
    expect(alien.retailVideoUsdPerMin, greaterThan(0));

    final gpt = offers.firstWhere((o) => o.id == 'live.chatgpt');
    expect(gpt.enabled, isTrue);
    expect(gpt.retailVideoUsdPerMin, greaterThan(0));

    final grok = offers.firstWhere((o) => o.id == 'live.grok');
    expect(grok.enabled, isTrue);
    expect(grok.retailVideoUsdPerMin, greaterThan(0));
  });

  test('liveOfferPricePerSecDualLocal formats dual voice and video price correctly', () {
    final alien = offers.firstWhere((o) => o.id == 'live.alienai');
    final formattedEn = liveOfferPricePerSecDualLocal(
      alien,
      currency: 'USD',
      fxMicroPerUsd: 1000000,
    );
    expect(formattedEn, contains('Voice:'));
    expect(formattedEn, contains('Video:'));

    final formattedIdr = liveOfferPricePerSecDualLocal(
      alien,
      currency: 'IDR',
      fxMicroPerUsd: 16000000000,
    );
    expect(formattedIdr, contains('~IDR'));
    expect(formattedIdr, contains('/s'));
  });
}
