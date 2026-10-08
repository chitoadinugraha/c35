// Site Team member helpers (CSA site_member.dart port).
// Wire roles: staff / manage / guest / owner (CSA employee->staff, manager->manage).

const siteMemberRoles = [
  ('staff', 'Staff'),
  ('manage', 'Manager'),
  ('guest', 'Guest'),
];

const siteMemberRoleOwner = 'owner';

/// Normalize CSA or wire role to c35 grant role (`staff` / `manage` / `guest` / `owner`).
String siteMemberRoleWire(String role) {
  final r = role.trim().toLowerCase();
  return switch (r) {
    'employee' => 'staff',
    'manager' => 'manage',
    _ => r,
  };
}

String siteMemberRoleLabel(String role) {
  final wire = siteMemberRoleWire(role);
  if (wire == siteMemberRoleOwner) return 'Owner';
  return siteMemberRoles.firstWhere((e) => e.$1 == wire, orElse: () => (role, role)).$2;
}

bool siteMemberIsManager(String role) {
  final r = siteMemberRoleWire(role);
  return r == siteMemberRoleOwner || r == 'manage';
}

String siteMemberDisplayName({String? displayName, required String email}) {
  final name = displayName?.trim();
  return name?.isNotEmpty == true ? name! : email;
}

String siteMemberInitials({String? displayName, required String email}) {
  final name = displayName?.trim();
  if (name?.isNotEmpty == true) {
    final parts = name!.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }
  return email.length >= 2 ? email.substring(0, 2).toUpperCase() : '?';
}

class SiteMemberDraft {
  const SiteMemberDraft({
    required this.id,
    required this.email,
    this.displayName = '',
    this.role = 'staff',
    this.avatarUrl = '',
    this.workShiftIds = const [],
    this.isViewer = false,
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final String avatarUrl;
  final List<String> workShiftIds;
  final bool isViewer;

  SiteMemberDraft copyWith({
    String? email,
    String? displayName,
    String? role,
    String? avatarUrl,
    List<String>? workShiftIds,
    bool? isViewer,
  }) =>
      SiteMemberDraft(
        id: id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        workShiftIds: workShiftIds ?? this.workShiftIds,
        isViewer: isViewer ?? this.isViewer,
      );
}
