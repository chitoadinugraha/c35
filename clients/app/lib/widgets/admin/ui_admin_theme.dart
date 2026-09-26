import 'package:flutter/material.dart';

const adminMuted = Color(0xFF71717A);
const adminText = Color(0xFFF4F4F5);
const adminPanel = Color(0xFF111114);
const adminBorder = Color(0xFF27272A);
const adminAccent = Color(0xFF34D399);
const adminAccentFg = Color(0xFF052E16);
const adminBarBg = Color(0xFF27272A);
const adminBarFill = Color(0xFF34D399);
const adminBarWarn = Color(0xFFFBBF24);
const adminBarCrit = Color(0xFFF87171);
const adminBarIn = Color(0xFF60A5FA);
const adminBarOut = Color(0xFF34D399);
const adminHealthOk = Color(0xFF34D399);
const adminHealthStale = Color(0xFFF87171);

const adminDashboardMaxWidth = 800.0;

class UiAdminSectionTitle extends StatelessWidget {
  const UiAdminSectionTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: const TextStyle(color: adminMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6),
        ),
      );
}

class UiAdminPanel extends StatelessWidget {
  const UiAdminPanel({super.key, required this.child, this.padding = const EdgeInsets.all(12)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: adminPanel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: adminBorder),
        ),
        child: child,
      );
}