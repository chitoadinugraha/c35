import 'package:alienai_c35/widgets/ui/ui_menu_position.dart';
import 'package:flutter/material.dart';

enum SkillAddAction { teach, install }

Future<SkillAddAction?> ioSkillAddMenuShow(BuildContext context, {required Offset position, bool showTeach = true}) => showMenu<SkillAddAction>(
      context: context,
      position: uiMenuPositionAt(context, position),
      color: const Color(0xFF18181B),
      items: [
        if (showTeach)
          const PopupMenuItem(
            value: SkillAddAction.teach,
            child: Row(
              children: [
                Icon(Icons.school_outlined, size: 18, color: Color(0xFFA1A1AA)),
                SizedBox(width: 10),
                Text('Teach', style: TextStyle(color: Color(0xFFE4E4E7), fontSize: 13)),
              ],
            ),
          ),
        const PopupMenuItem(
          value: SkillAddAction.install,
          child: Row(
            children: [
              Icon(Icons.download_outlined, size: 18, color: Color(0xFF34D399)),
              SizedBox(width: 10),
              Text('Install', style: TextStyle(color: Color(0xFFE4E4E7), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
