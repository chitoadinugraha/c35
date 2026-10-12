from pathlib import Path
p = Path(r"D:\c35\clients\app\lib\guest_site\guest_site_assistant.dart")
t = p.read_text(encoding="utf-8")
if "guest_assistant_api" not in t:
    t = t.replace(
        "import 'package:alienai_c35/c/site/site_ai_assistant.dart';",
        "import 'package:alienai_c35/c/site/guest_assistant_api.dart';\nimport 'package:alienai_c35/c/site/site_ai_assistant.dart';",
        1,
    )
start = t.find("class _GuestChatPanel extends StatelessWidget {")
end = t.find("\n\nclass _AssistantFab")
assert start >= 0 and end > start
# minimal: only add import + siteIid to panel call for now - full panel in separate file?
p.write_text(t, encoding="utf-8", newline="\n")
print("import only", start, end)