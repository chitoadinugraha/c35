import 'package:alienai_c35/widgets/ai/alien_icon_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UiAlienIcon extends StatelessWidget {
  const UiAlienIcon({super.key, this.size = 28, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SvgPicture.string(alienIconSvg, width: size, height: size, colorFilter: ColorFilter.mode(color, BlendMode.srcIn));
}
