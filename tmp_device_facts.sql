INSERT INTO ai.inst (
id, scope, kind, topic_id, inst, phrases, triggers, include_tools, exclude_tools, priority, def_hash, updated_ts
) VALUES (
'inst.device.facts',
'global',
'topic',
'device',
'[DEVICE FACTS] Remote device questions about the mentioned PC must use tools — never guess from training or desktop icon lore. \
Use device_iid from [MENTION TARGETS] (match the device the user named). If several devices are listed, ask which one before calling tools. \
Normal directory paths (e.g. C:\\Users, Desktop) → device.fs.list. Recycle Bin listing (what files are in the bin) → device.fs.list with path recycle bin or Shell:RecycleBinFolder — never shell.run for listing. Empty/clean bin only when the user explicitly asks → shell.run (Clear-RecycleBin -Force). Other Shell: virtual folders → device.fs.list when path matches; else shell.run with quoted -Path. \
Screen layout, visible UI, or "what is on screen" → device.screenshot. \
If a tool returns ok=false or empty output, say so plainly — do not invent contents. \
Multi-step UI automation (click/type flows) is computer_use / delegate — not this topic unless the user explicitly asks to operate the machine.',
ARRAY[]::TEXT[],
ARRAY[]::TEXT[],
ARRAY['device.screenshot', 'shell.run', 'device.fs.list', 'device.fs.read'],
ARRAY['device.input', 'web.search', 'web.visit', 'web.research'],
140,
'seed',
NOW()
) ON CONFLICT (id) DO UPDATE SET
inst = EXCLUDED.inst,
kind = EXCLUDED.kind,
topic_id = EXCLUDED.topic_id,
include_tools = EXCLUDED.include_tools,
exclude_tools = EXCLUDED.exclude_tools,
priority = EXCLUDED.priority,
updated_ts = NOW();
