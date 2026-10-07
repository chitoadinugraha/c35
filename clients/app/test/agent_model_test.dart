import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('thinkingStatusLabel uses Alien AI for auto router', () {
    expect(AgentModel.alien.thinkingStatusLabel, 'Alien AI is thinking');
  });

  test('thinkingStatusLabel shortens Gemini Flash models', () {
    const m = AgentModel(
      id: 'gemini-2.5-flash',
      chip: 'Gemini 2.5',
      label: 'Gemini 2.5 Flash',
      provider: 'google',
      providerModel: 'gemini-2.5-flash',
    );
    expect(m.thinkingStatusLabel, 'Gemini 2.5 Flash is thinking');
  });
}
