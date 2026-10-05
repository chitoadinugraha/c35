import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/widgets/ai/ui_assistant_provider_icon.dart';
import 'package:flutter/material.dart';

String liveOfferIconProvider(LiveOffer offer) {
  if (offer.family == 'alienai') return 'alienai';
  return switch (offer.provider) {
    'google' => 'google',
    'openai' => 'openai',
    'xai' => 'xai',
    _ => switch (offer.family) {
        'gemini' => 'google',
        'openai' => 'openai',
        'xai' => 'xai',
        _ => 'google',
      },
  };
}

class UiLiveOfferIcon extends StatelessWidget {
  const UiLiveOfferIcon({super.key, required this.offer, this.size = 16, this.dimmed = false});

  final LiveOffer offer;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) =>
      UiAssistantProviderIcon(provider: liveOfferIconProvider(offer), size: size, dimmed: dimmed);
}
