import 'package:alienai_c35/widgets/ui/ui_page_bar.dart';
import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'package:flutter/material.dart';

const uiPageBg = Color(0xFF08080A);

class UiPage extends StatelessWidget {
  const UiPage({
    super.key,
    required this.title,
    this.subtitle,
    this.titleWidget,
    this.onBack,
    this.trailing,
    required this.body,
    this.backgroundColor = uiPageBg,
    this.overlay,
    this.floatingActionButton,
  });

  final String title;
  final String? subtitle;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget body;
  final Color backgroundColor;
  final Widget? overlay;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final bar = UiPageBar(title: title, subtitle: subtitle, titleWidget: titleWidget, onBack: onBack, trailing: trailing);
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              uiDesktopWindow ? bar : SafeArea(bottom: false, child: bar),
              Expanded(child: body),
            ],
          ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}
