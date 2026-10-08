import 'package:flutter/material.dart';

const _border = Color(0xFF3F3F46);
const _muted = Color(0xFF71717A);

class SiteCatalogMenuItem {
  const SiteCatalogMenuItem({required this.value, required this.label, this.leading, this.enabled = true});

  final String value;
  final String label;
  final Widget? leading;
  final bool enabled;
}

class UiSiteCatalogToolbar extends StatelessWidget {
  const UiSiteCatalogToolbar({
    super.key,
    required this.searchController,
    required this.hintText,
    required this.onSearchChanged,
    this.onAdd,
    this.addBusy = false,
    this.addTooltip = 'Add',
    this.onPaste,
    this.onImportImage,
    this.designSelected = false,
    this.onDesignToggle,
    this.extraActions,
    this.menuItems,
    this.onMenuAction,
  });

  final TextEditingController searchController;
  final String hintText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onAdd;
  final bool addBusy;
  final String addTooltip;
  final VoidCallback? onPaste;
  final VoidCallback? onImportImage;
  final bool designSelected;
  final VoidCallback? onDesignToggle;
  final List<Widget>? extraActions;
  final List<SiteCatalogMenuItem>? menuItems;
  final ValueChanged<String>? onMenuAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hintText,
                  hintStyle: const TextStyle(color: _muted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18, color: _muted),
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF34D399)),
                  ),
                ),
              ),
            ),
            if (onPaste != null || onImportImage != null) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: 'Import',
                icon: const Icon(Icons.more_vert, size: 20, color: _muted),
                onSelected: (v) {
                  if (v == 'paste') onPaste?.call();
                  if (v == 'image') onImportImage?.call();
                },
                itemBuilder: (ctx) => [
                  if (onPaste != null) const PopupMenuItem(value: 'paste', child: Text('Paste products')),
                  if (onImportImage != null) const PopupMenuItem(value: 'image', child: Text('From image')),
                ],
              ),
            ],
            if (onDesignToggle != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: 'Catalog design',
                child: IconButton(
                  onPressed: onDesignToggle,
                  icon: Icon(Icons.palette_outlined, size: 20, color: designSelected ? const Color(0xFF34D399) : _muted),
                ),
              ),
            ],
            if (extraActions != null) ...extraActions!,
            if (menuItems != null && menuItems!.isNotEmpty) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: addTooltip,
                icon: const Icon(Icons.person_add_outlined, size: 20, color: _muted),
                onSelected: onMenuAction,
                itemBuilder: (ctx) => [
                  for (final item in menuItems!)
                    PopupMenuItem(
                      value: item.value,
                      enabled: item.enabled,
                      child: Row(
                        children: [
                          if (item.leading != null) ...[item.leading!, const SizedBox(width: 10)],
                          Text(item.label),
                        ],
                      ),
                    ),
                ],
              ),
            ] else if (onAdd != null) ...[
              const SizedBox(width: 4),
              addBusy
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Tooltip(
                      message: addTooltip,
                      child: IconButton(onPressed: onAdd, icon: const Icon(Icons.add, size: 20)),
                    ),
            ],
          ],
        ),
      );
}
