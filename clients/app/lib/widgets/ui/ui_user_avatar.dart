import 'package:alienai_c35/c/profile/profile_handle.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

String userAvatarInitials({required String name, String email = '', String handle = ''}) {
  final e = email.trim().isNotEmpty ? email : profileAlienAddress(handle);
  final n = name.trim();
  if (n.isNotEmpty) {
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }
  return e.isNotEmpty ? e[0].toUpperCase() : '?';
}

class UiUserAvatar extends StatelessWidget {
  const UiUserAvatar({super.key, required this.name, this.email = '', this.handle = '', this.pic = '', this.size = 20, this.showBorder = false});

  final String name;
  final String email;
  final String handle;
  final String pic;
  final double size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final fallback = _InitialsAvatar(initials: userAvatarInitials(name: name, email: email, handle: handle), size: size);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: showBorder ? Border.all(color: const Color(0xFF3F3F46)) : null),
      clipBehavior: Clip.antiAlias,
      child: pic.trim().isEmpty ? fallback : UiImg(src: pic, fit: BoxFit.cover, width: size, height: size, fallback: fallback),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF71717A), Color(0xFF3F3F46)]),
          ),
          child: Center(child: Text(initials, style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w700, color: const Color(0xFFF4F4F5)))),
        ),
      );
}
