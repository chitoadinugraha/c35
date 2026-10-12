const siteLinkDisplayList = 'list';
const siteLinkDisplayIcon = 'icon';
const siteLinkDisplayCard = 'card';

const siteLinkDisplayOptions = <(String id, String label)>[
  (siteLinkDisplayList, 'List'),
  (siteLinkDisplayIcon, 'Icon'),
  (siteLinkDisplayCard, 'Card'),
];

String siteLinkDisplayNormalize(String raw) {
  final s = raw.trim().toLowerCase();
  return switch (s) {
    '' => siteLinkDisplayList,
    'icon_label' || 'chip' => siteLinkDisplayList,
    siteLinkDisplayList || siteLinkDisplayIcon || siteLinkDisplayCard => s,
    _ => siteLinkDisplayList,
  };
}

String siteLinkDisplayLabel(String mode) => switch (siteLinkDisplayNormalize(mode)) {
      siteLinkDisplayCard => 'Card',
      siteLinkDisplayIcon => 'Icon',
      _ => 'List',
    };
