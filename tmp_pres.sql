INSERT INTO ai.inst (
id, scope, kind, topic_id, inst, phrases, triggers, include_tools, exclude_tools, priority, def_hash, updated_ts
) VALUES (
'inst.presentation',
'global',
'task',
'',
'[PRESENTATION] User wants to create a presentation, slide deck, pitch deck, or PowerPoint. \
0. STRUCTURE & FAST PATH: \
- Slide 1 is ALWAYS the Title / Cover slide: `# Presentation Title\nSubheadline or tagline` (NO bullet points on slide 1 so it renders as a dedicated cover slide). \
- Slides 2+ are Content slides: `# Section Title\n- Key point 1\n- Key point 2`. \
- Pictures: Add photos / illustrations to any slide using markdown `![caption](image_url)` (e.g. Unsplash URL, attachment, or generate with img.generate). \
- THEME SELECTION (CRITICAL): Always pass the most fitting `theme` parameter in presentation.create based on topic mood and audience (never pick randomly or default blindly to dark): \
* Dating / romance / relationships / personal lifestyle: "sunset" (warm plum/pink) or "ruby" (rose/red) or "sakura" (blossom light) \
* Business / finance / investing / corporate / ESG: "emerald" (emerald modern) \
* Startup / cloud / SaaS / enterprise / executive: "midnight" (deep indigo) or "ocean" (deep cyan) \
* Creative / design / UI/UX / AI apps: "lavender" (amethyst violet) \
* Nature / agriculture / plants / botanical / wellness: "forest" (botanical moss/sage) \
* Food / culinary / cafe / coffee / craft / history: "coffee" (mocha caramel) \
* Luxury / VIP / wealth / legal / awards: "gold" (royal gold) \
* Gaming / esports / Web3 / crypto / nightlife / sci-fi: "cyberpunk" (neo tokyo pink/cyan) \
* Science / maritime / data analytics / clean energy: "ocean" or "aurora" (boreal teal) \
* Minimalist / architecture / engineering / typography: "monochrome" (bauhaus slate b&w) \
* Books / editorial / magazine / warm paper: "cream" (editorial warm terracotta) \
* Academic / research paper / daylight light-mode: "arctic" (clean light mode) \
* Cyber / hacker / terminal / developer tooling: "dark" (dark neon orange) \
* If user specifies a theme or light/dark style, strictly honor it. \
- Immediately call tool presentation.create(title, slides_markdown, theme) or output in a ```slide code block with slides separated by "
1. SLIDE PATCHING (CRITICAL): When the user asks to edit, tweak, add a picture, or update a slide, NEVER rewrite the entire presentation. Call tool presentation.patch(slide_index, action, content) or output ONLY a targeted patch: \
<!
# Slide Title \
- updated bullet 1 \
- updated bullet 2 \
![Photo description](image_url) \
To add: <!
2. SOURCES: If source materials are attached (PDF, YouTube link, notes), inspect section titles / chapters first before writing. \
3. EXPORT & BUILD: (a) Export to PowerPoint (.pptx) via presentation.export, (b) Copy Markdown, or (c) Google Slides.',
ARRAY[
'presentation', 'presentasi', 'slide', 'slides', 'slide deck',
'bikin slide', 'buat slide', 'bikin presentasi', 'buat presentasi',
'pitch deck', 'powerpoint', 'keynote', 'deck', 'marp', 'slide-patch'
],
ARRAY['tool_include:presentation.create', 'tool_include:presentation.patch']::TEXT[],
ARRAY['presentation.create', 'presentation.patch', 'presentation.export', 'img.generate', 'presentation.source.structure', 'presentation.source.extract', 'presentation.source.video_structure', 'presentation.source.video_extract'],
ARRAY['web.search', 'web.visit'],
150,
'seed',
NOW()
) ON CONFLICT (id) DO UPDATE SET
inst = EXCLUDED.inst,
phrases = EXCLUDED.phrases,
triggers = EXCLUDED.triggers,
include_tools = EXCLUDED.include_tools,
exclude_tools = EXCLUDED.exclude_tools,
kind = EXCLUDED.kind,
priority = EXCLUDED.priority,
updated_ts = NOW();