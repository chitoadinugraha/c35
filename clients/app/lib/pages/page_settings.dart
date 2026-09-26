import 'dart:async';

import 'package:alienai_c35/c/account/account_api.dart';
import 'package:alienai_c35/c/account/invoke_account.dart';
import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/api/settings_conn.dart';
import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:alienai_c35/c/locale/app_locale.dart';
import 'package:alienai_c35/c/parts/version_label.dart';
import 'package:alienai_c35/c/update/app_release.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:alienai_c35/c/profile/profile_api.dart';
import 'package:alienai_c35/c/profile/profile_handle.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/location/location_permission.dart';
import 'package:alienai_c35/c/location/location_service.dart';
import 'package:alienai_c35/c/location/user_location_prefs.dart';
import 'package:alienai_c35/c/settings/user_locale_prefs.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/task/task_trigger_cron.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/c/stt/stt_mic_permission.dart';
import 'package:alienai_c35/c/stt/stt_service.dart';
import 'package:alienai_c35/c/tts/speech_lang.dart';
import 'package:record/record.dart' show InputDevice;
import 'package:alienai_c35/c/tts/tts_service.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/voice/voice_api.dart';
import 'package:alienai_c35/pages/finance/page_finance_payments.dart';
import 'package:alienai_c35/pages/finance/page_finance_receive_accounts.dart';
import 'package:alienai_c35/pages/page_allow_control.dart' show ThisPcRegister;
import 'package:alienai_c35/pages/mail/page_mail.dart';
import 'package:alienai_c35/pages/page_root_console.dart';
import 'package:alienai_c35/c/auth/auth_service.dart';
import 'package:alienai_c35/widgets/ai/ui_bot_memories_sheet.dart';
import 'package:alienai_c35/widgets/skill/ui_skill_master_detail.dart';
import 'package:alienai_c35/widgets/io/in_alien_id_signup.dart';
import 'package:alienai_c35/widgets/io/in_referral_code.dart';
import 'package:alienai_c35/widgets/settings/ui_account_live_conns.dart';
import 'package:alienai_c35/widgets/settings/ui_settings_password.dart';
import 'package:alienai_c35/widgets/settings/ui_settings_pin.dart';
import 'package:alienai_c35/widgets/settings/io_chat_history_clear_dialog.dart';
import 'package:alienai_c35/widgets/settings/ui_settings_tile.dart';
import 'package:alienai_c35/widgets/settings/ui_settings_unlock_mode.dart';
import 'package:alienai_c35/widgets/ui/ui_account_role_badges.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:alienai_c35/widgets/ui/ui_locale_picker_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:alienai_c35/widgets/ui/ui_speak_toggle.dart' show UiAppToggle;
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PageSettings extends StatefulWidget {
  PageSettings({super.key, AppStore? store, this.conn, this.chatConn, this.chatStore, this.thisPcRegister, this.thisPcUnregister, this.profile, this.account, this.auth}) : store = store ?? AppStore.instance;
  final AppStore store;
  final SettingsConn? conn;
  final ChatConn? chatConn;
  final ChatStore? chatStore;
  final ThisPcRegister? thisPcRegister;
  final Future<void> Function()? thisPcUnregister;
  final ProfileApi? profile;
  final AccountApi? account;
  final AuthService? auth;

  @override
  State<PageSettings> createState() => _PageSettingsState();
}

class _PageSettingsState extends State<PageSettings> {
  static const _bg = Color(0xFF08080A);
  static const _border = Color(0xFF27272A);
  static const _accent = Color(0xFF34D399);
  static const _contentMaxWidth = 720.0;

  late final ProfileApi? _profile = widget.profile ?? (widget.conn == null ? null : ProfileApi(invoke: widget.conn!.authInvoke));
  late final AccountApi? _account = widget.account ?? (widget.conn == null ? null : AccountApi(invoke: widget.conn!.authInvoke, uid: Session.instance.uid));
  late final AuthService _auth = widget.auth ?? AuthService();
  late String _name = Session.instance.name;
  late String _email = Session.instance.email;
  late String _handle = Session.instance.handle;
  late String _pic = Session.instance.pic;
  var _busy = false;
  var _hasPassword = false;
  var _hasPin = false;
  var _unlockMode = 'tap';
  late String _serverLabel = '';
  late String _speechLang = VoicePrefs.instance.speechLang;
  late String _sttEngine = VoicePrefs.instance.sttEngine;
  late String _ttsEngine = VoicePrefs.instance.ttsEngine;
  late double _speechRate = VoicePrefs.instance.speechRate;
  late double _speechPitch = VoicePrefs.instance.speechPitch;
  late bool _showUsageStats = PromptUsagePrefs.instance.showUsageStats;
  late String _tz = UserLocalePrefs.instance.tz;
  late String _locationCity = UserLocalePrefs.instance.locationCity;
  late String _locationRegion = UserLocalePrefs.instance.locationRegion;
  late String _locationCountry = UserLocalePrefs.instance.locationCountry;
  late String _locationSource = UserLocalePrefs.instance.locationSource;
  var _locationManualExpanded = UserLocalePrefs.instance.locationSource.trim().toLowerCase() == 'user';
  String _apkUrl = '';
  List<InputDevice> _audioInputDevices = const [];
  InputDevice? _resolvedDefaultMic;

  @override
  void initState() {
    super.initState();
    if (widget.chatConn != null) {
      final api = VoiceApi(widget.chatConn!);
      SttService.instance.bindVoiceApi(api);
      TtsService.instance.bindVoiceApi(api);
    }
    sessionTick.addListener(_onSessionTick);
    VoicePrefs.instance.addListener(_onVoiceChanged);
    PromptUsagePrefs.instance.addListener(_onUsagePrefsChanged);
    UserLocalePrefs.instance.addListener(_onLocalePrefsChanged);
    unawaited(_loadAudioDevices());
    unawaited(_hydrate());
  }

  Future<void> _loadAudioDevices() async {
    try {
      final devices = await SttService.instance.listInputDevices();
      final resolved = await SttService.instance.resolveActiveMicDevice();
      debugPrint('[PageSettings] _loadAudioDevices: found ${devices.length} devices');
      for (final d in devices) {
        debugPrint('[PageSettings]   device: "${d.label}" (${d.id})');
      }
      debugPrint('[PageSettings]   resolved default: "${resolved?.label}" (${resolved?.id})');
      if (!mounted) return;
      setState(() {
        _audioInputDevices = devices;
        _resolvedDefaultMic = resolved;
      });
    } catch (e, st) {
      debugPrint('[PageSettings] _loadAudioDevices error: $e\n$st');
    }
  }

  Future<void> _hydrate() async {
    final host = await serverHostFooterLabel();
    var apkUrl = '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      final base = await serverHostActiveBase();
      final release = await appReleaseGet(base, platform: 'android');
      apkUrl = release?.apkUrl ?? '';
    }
    UserSettingsRes? settings;
    try {
      settings = await _account?.userSettingsGet();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _name = Session.instance.name;
      _email = Session.instance.email;
      _handle = Session.instance.handle;
      _pic = Session.instance.pic;
      _serverLabel = host;
      _apkUrl = apkUrl;
      if (settings != null) {
        _hasPassword = settings.hasPassword;
        _hasPin = settings.hasPin;
        _unlockMode = settings.sessionUnlockMode;
      }
    });
    if (!mounted) return;
    await _locationSyncFromServer();
    await _loadAudioDevices();
  }

  @override
  void dispose() {
    sessionTick.removeListener(_onSessionTick);
    VoicePrefs.instance.removeListener(_onVoiceChanged);
    PromptUsagePrefs.instance.removeListener(_onUsagePrefsChanged);
    UserLocalePrefs.instance.removeListener(_onLocalePrefsChanged);
    super.dispose();
  }

  void _onSessionTick() {
    if (!mounted) return;
    setState(() {
      _name = Session.instance.name;
      _email = Session.instance.email;
      _handle = Session.instance.handle;
      _pic = Session.instance.pic;
    });
  }

  void _onVoiceChanged() {
    if (!mounted) return;
    setState(() {
      _speechLang = VoicePrefs.instance.speechLang;
      _sttEngine = VoicePrefs.instance.sttEngine;
      _ttsEngine = VoicePrefs.instance.ttsEngine;
      _speechRate = VoicePrefs.instance.speechRate;
      _speechPitch = VoicePrefs.instance.speechPitch;
    });
  }

  void _onUsagePrefsChanged() {
    if (!mounted) return;
    setState(() => _showUsageStats = PromptUsagePrefs.instance.showUsageStats);
  }

  void _onLocalePrefsChanged() {
    if (!mounted) return;
    setState(() {
      _tz = UserLocalePrefs.instance.tz;
      _locationCity = UserLocalePrefs.instance.locationCity;
      _locationRegion = UserLocalePrefs.instance.locationRegion;
      _locationCountry = UserLocalePrefs.instance.locationCountry;
      _locationSource = UserLocalePrefs.instance.locationSource;
      _locationManualExpanded = UserLocalePrefs.instance.locationSource.trim().toLowerCase() == 'user';
    });
  }

  String _locationSourceLabel(String source) {
    final s = source.trim().toLowerCase();
    if (s == 'device') return 'settings.locationSourceDevice'.tr();
    if (s == 'ip') return 'settings.locationSourceIp'.tr();
    if (s == 'user') return 'settings.locationSourceUser'.tr();
    return 'settings.locationSourceUnknown'.tr();
  }

  String _locationPlaceSummary() {
    final parts = [_locationCity, _locationRegion, _locationCountry].map((s) => s.trim()).where((s) => s.isNotEmpty);
    return parts.join(', ');
  }

  Future<void> _locationSyncFromServer() async {
    if (widget.chatConn == null || widget.chatStore == null) return;
    if (UserLocalePrefs.instance.locationManualLocked) return;
    final locale = mounted ? context.locale.toString() : 'en';
    await widget.chatStore!.refreshFromConn(widget.chatConn!, locale: locale);
  }

  Future<void> _tzPrefsSave() async {
    await UserLocalePrefs.instance.put(tz: _tz);
    await _localePrefsSyncConn();
  }

  Future<void> _locationManualSave() async {
    await UserLocationPrefs.instance.put(useDevice: false, locationSource: 'user');
    await UserLocalePrefs.instance.put(
      locationCity: _locationCity,
      locationRegion: _locationRegion,
      locationCountry: _locationCountry,
      locationSource: 'user',
    );
    if (!mounted) return;
    setState(() {
      _locationSource = 'user';
      _locationManualExpanded = true;
    });
    await _localePrefsSyncConn();
  }

  Future<void> _localePrefsSyncConn() async {
    final locale = context.locale.toString();
    if (widget.chatConn != null && widget.chatStore != null) {
      await widget.chatStore!.refreshFromConn(widget.chatConn!, locale: locale);
    }
  }

  Future<void> _locationUseDevice() async {
    if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) return;
    final granted = await locationPermissionEnsure();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('settings.locationDeniedSnack'.tr()), behavior: SnackBarBehavior.floating));
      return;
    }
    locationServiceCacheClear();
    final loc = await locationServiceResolve(force: true);
    if (loc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('settings.locationDeniedSnack'.tr()), behavior: SnackBarBehavior.floating));
      return;
    }
    await UserLocationPrefs.instance.put(asked: true, useDevice: true, locationSource: 'device');
    await UserLocalePrefs.instance.put(
      locationCity: loc.city,
      locationRegion: loc.region,
      locationCountry: loc.country,
      locationSource: 'device',
    );
    if (!mounted) return;
    setState(() {
      _locationCity = loc.city;
      _locationRegion = loc.region;
      _locationCountry = loc.country;
      _locationSource = 'device';
      _locationManualExpanded = false;
    });
    await _localePrefsSyncConn();
  }

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyProfile({String? name, String? avatarUrl, String? handle, String? authEmail}) async {
    final api = _profile;
    if (api == null) return;
    final res = await api.put(uid: Session.instance.uid, name: name, avatarUrl: avatarUrl, handle: handle, authEmail: authEmail);
    if (!mounted) return;
    setState(() {
      _name = res.name.isNotEmpty ? res.name : _name;
      _email = res.authEmail.isNotEmpty ? res.authEmail : _email;
      _handle = res.handle.isNotEmpty ? res.handle : _handle;
      _pic = res.avatarUrl.isNotEmpty ? res.avatarUrl : _pic;
    });
    await Session.instance.put(uid: Session.instance.uid, name: _name, handle: _handle, pic: _pic, email: _email);
  }

  Future<void> _editName() async {
    final trimmed = await showDialog<String>(context: context, builder: (ctx) => _ProfileTextDialog(title: 'Change name', label: 'Name', initial: _name, onSubmit: (v) => v.trim().isNotEmpty ? v.trim() : null));
    if (trimmed == null || trimmed == _name) return;
    await _run(() => _applyProfile(name: trimmed));
  }

  Future<void> _editAlienId() async {
    final initial = alienIdSignupNorm(_handle);
    final trimmed = await showDialog<String>(context: context, builder: (ctx) => _AlienIdDialog(initial: initial));
    if (trimmed == null || trimmed == initial) return;
    await _run(() async {
      final claimed = await _auth.claimAlienId(alienId: trimmed);
      if (!mounted) return;
      setState(() {
        _handle = '@$claimed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alien ID set to @$claimed'), behavior: SnackBarBehavior.floating),
      );
    });
  }

  Future<void> _editReferralCode() async {
    if (Session.instance.hasReferrer) return;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => _ReferralCodeDialog(auth: _auth));
    if (ok == true && mounted) setState(() {});
  }

  Future<void> _languagePick() async {
    final picked = await askAppLocale(context: context, value: context.locale);
    if (picked == null || !mounted) return;
    if (appLocaleSame(picked, context.locale)) return;
    await context.setLocale(picked);
  }

  Future<void> _cycleHost() async {
    if (!serverHostPickerVisible()) return;
    final next = await serverHostCycle();
    if (!mounted) return;
    setState(() => _serverLabel = serverHostLabelFromUrl(next));
  }

  void _openSkills() {
    final conn = widget.chatConn;
    if (conn == null) return;
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageSkills(conn: conn, ownerIid: Session.instance.uid)));
  }

  Future<void> _clearChatHistory() async {
    final conn = widget.chatConn;
    final store = widget.chatStore;
    if (conn == null || store == null) return;
    final ok = await chatHistoryClearConfirmShow(context, conn: conn, store: store);
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settings.clearChatHistoryDone'.tr()), behavior: SnackBarBehavior.floating),
      );
    }
  }

  bool get _financeRole => Session.instance.isRoot || Session.instance.globalRoles.contains('finance');

  bool get _receiveAccountRole => Session.instance.isRoot || Session.instance.globalRoles.any((r) => r == 'finance' || r == 'director');

  void _openRootConsole() {
    final conn = widget.chatConn;
    if (conn == null) return;
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageRootConsole(chatConn: conn)));
  }

  void _openFinancePayments() => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PageFinancePayments(conn: ReferralConn(uid: Session.instance.uid), canReview: _financeRole),
        ),
      );

  void _openFinanceReceiveAccounts() => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => PageFinanceReceiveAccounts(conn: ReferralConn(uid: Session.instance.uid))),
      );

  UiAccountRoleBadgesAction get _badgeAction => UiAccountRoleBadgesAction(
        onRootConsole: Session.instance.isRoot && widget.chatConn != null ? _openRootConsole : null,
        onFinancePayments: _financeRole ? _openFinancePayments : null,
        onFinanceReceiveAccounts: _receiveAccountRole ? _openFinanceReceiveAccounts : null,
      );

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent)),
      );

  @override
  Widget build(BuildContext context) {
    final alienHandle = profileAlienAddress(_handle);
    final account = _account;
    return UiPage(
      title: 'settings.title'.tr(),
      onBack: () => Navigator.pop(context),
      backgroundColor: _bg,
      overlay: _busy ? const Positioned(left: 0, right: 0, top: 0, child: LinearProgressIndicator(minHeight: 2, color: _accent, backgroundColor: Colors.transparent)) : null,
      body: ListenableBuilder(
              listenable: widget.store,
              builder: (context, _) => SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        _SectionLabel('settings.sectionProfile'.tr()),
                        const SizedBox(height: 8),
                        _Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              UiUserAvatar(name: _name, email: _email, pic: _pic, size: 64),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _ProfileTapRow(label: 'Name', onTap: _busy ? null : _editName, child: Text(_name.isEmpty ? 'Account' : _name, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.bold))),
                                  const SizedBox(height: 8),
                                  _ProfileTapRow(label: 'Email', child: Text(_email.isEmpty ? '—' : _email, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13))),
                                  const SizedBox(height: 4),
                                  _ProfileTapRow(
                                    label: 'Alien ID',
                                    onTap: _busy ? null : _editAlienId,
                                    child: Text(
                                      _handle.isEmpty ? 'Not set (Tap to claim Alien ID)' : alienHandle,
                                      style: TextStyle(
                                        color: _handle.isEmpty ? const Color(0xFF34D399) : const Color(0xFFA1A1AA),
                                        fontSize: 13,
                                        fontWeight: _handle.isEmpty ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (!Session.instance.hasReferrer) ...[
                                    const SizedBox(height: 4),
                                    _ProfileTapRow(
                                      label: 'Referral Code',
                                      onTap: _busy ? null : _editReferralCode,
                                      child: const Text(
                                        'Not set (Tap to enter referral code)',
                                        style: TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  UiAccountRoleBadges(action: _badgeAction, size: UiAccountRoleBadgeSize.page),
                                ]),
                              ),
                            ]),
                          ),
                        ),
                        if (Session.instance.canUseMail && widget.chatConn != null) ...[
                          const SizedBox(height: 28),
                          _SectionLabel('mail.title'.tr()),
                          const SizedBox(height: 8),
                          _Card(
                            child: UiSettingsTile(
                              icon: Icons.mail_outlined,
                              title: 'mail.title'.tr(),
                              subtitle: 'mail.inbox'.tr(),
                              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageMail(chatConn: widget.chatConn!))),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        _SectionLabel('Billing'),
                        const SizedBox(height: 8),
                        _Card(
                          child: Column(children: [
                            UiSettingsTile(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'settings.balance'.tr(),
                              subtitle: moneyBalanceLabel(widget.store.wallet.balanceUsd, currency: widget.store.wallet.billingCurrency, fxMicroPerUsd: widget.store.wallet.fxMicroPerUsd),
                            ),
                            if (widget.store.wallet.allow5hLimit > 0) ...[
                              uiSettingsDivider(),
                              UiSettingsTile(
                                icon: Icons.hourglass_top_outlined,
                                title: 'Free allowance',
                                subtitle: '${moneyAllowanceLabel((widget.store.wallet.allow5hLimit - widget.store.wallet.allow5hUsed).clamp(0.0, widget.store.wallet.allow5hLimit), currency: widget.store.wallet.billingCurrency, fxMicroPerUsd: widget.store.wallet.fxMicroPerUsd)} remaining of ${moneyAllowanceLabel(widget.store.wallet.allow5hLimit, currency: widget.store.wallet.billingCurrency, fxMicroPerUsd: widget.store.wallet.fxMicroPerUsd)} (5h)',
                              ),
                            ],
                          ]),
                        ),
                        const SizedBox(height: 28),
                        _SectionLabel('settings.sectionAi'.tr()),
                        const SizedBox(height: 8),
                        _Card(
                          child: Column(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(children: [
                                const Icon(Icons.data_usage_outlined, color: Color(0xFF71717A), size: 22),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('settings.showUsage'.tr(), style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 14, fontWeight: FontWeight.w500)), const SizedBox(height: 2), Text('settings.showUsageSubtitle'.tr(), style: const TextStyle(color: Color(0xFF71717A), fontSize: 12))])),
                                UiAppToggle(value: _showUsageStats, onChanged: (v) { setState(() => _showUsageStats = v); PromptUsagePrefs.instance.setShowUsageStats(v); }),
                              ]),
                            ),
                            uiSettingsDivider(),
                            UiSettingsTile(
                              icon: Icons.psychology_outlined,
                              title: 'Learned Memories',
                              subtitle: 'settings.learnedMemoriesSubtitle'.tr(),
                              onTap: widget.conn == null ? null : () => UiBotMemoriesSheet.show(context, conn: widget.conn!),
                            ),
                            uiSettingsDivider(),
                            UiSettingsTile(
                              icon: Icons.auto_awesome_outlined,
                              title: 'Skills',
                              subtitle: 'Installed skills for your personal assistant',
                              onTap: widget.chatConn == null ? null : _openSkills,
                            ),
                            uiSettingsDivider(),
                            UiSettingsTile(
                              icon: Icons.delete_sweep_outlined,
                              title: 'settings.clearChatHistory'.tr(),
                              subtitle: 'settings.clearChatHistorySubtitle'.tr(),
                              onTap: widget.chatConn == null || widget.chatStore == null ? null : _clearChatHistory,
                            ),
                          ]),
                        ),
                        if (account != null) ...[
                          const SizedBox(height: 28),
                          _SectionLabel('settings.sectionSecurity'.tr()),
                          const SizedBox(height: 8),
                          _Card(
                            child: Column(children: [
                              UiSettingsPassword(account: account, hasPassword: _hasPassword, onPasswordChanged: (v) => setState(() => _hasPassword = v)),
                              uiSettingsDivider(),
                              UiSettingsPin(account: account, hasPin: _hasPin, onPinChanged: (v) => setState(() => _hasPin = v)),
                              uiSettingsDivider(),
                              UiSettingsUnlockMode(account: account, currentMode: _unlockMode, hasPin: _hasPin, onModeChanged: (v) => setState(() => _unlockMode = v)),
                              uiSettingsDivider(),
                              UiSettingsTile(icon: Icons.devices_other_outlined, title: 'settings.activeConnections'.tr(), subtitle: 'settings.activeConnectionsSubtitle'.tr(), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageAccountLiveConns(account: account)))),
                            ]),
                          ),
                        ],
                        if (defaultTargetPlatform == TargetPlatform.android && _apkUrl.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          const _SectionLabel('App'),
                          const SizedBox(height: 8),
                          _Card(
                            child: UiSettingsTile(
                              icon: Icons.android_outlined,
                              title: 'Download APK',
                              subtitle: 'Install without Google Play',
                              onTap: () => launchUrl(Uri.parse(_apkUrl), mode: LaunchMode.externalApplication),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        _SectionLabel('settings.sectionAppearance'.tr()),
                        const SizedBox(height: 8),
                        _Card(
                          child: UiSettingsTile(
                            leading: UiImg(src: appLocaleMeta(context.locale).flag, width: 22, height: 22, recolor: false),
                            title: 'settings.language'.tr(),
                            subtitle: appLocaleLabel(context.locale),
                            onTap: _languagePick,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _SectionLabel('settings.sectionLocationTime'.tr()),
                        const SizedBox(height: 8),
                        _Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Builder(
                              builder: (context) {
                                final place = _locationPlaceSummary();
                                final source = _locationSource.trim().toLowerCase();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (place.isNotEmpty)
                                      Text(
                                        place,
                                        style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 15, fontWeight: FontWeight.w500),
                                      )
                                    else
                                      Text(
                                        'settings.locationPlaceUnset'.tr(),
                                        style: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'settings.locationSource'.tr(namedArgs: {'source': _locationSourceLabel(_locationSource)}),
                                      style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                                    ),
                                    if (source == 'ip' && place.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'settings.locationIpHint'.tr(),
                                        style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                                      ),
                                    ],
                                    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) ...[
                                      const SizedBox(height: 10),
                                      OutlinedButton.icon(
                                        onPressed: _busy ? null : () => _run(_locationUseDevice),
                                        icon: const Icon(Icons.my_location_outlined, size: 18),
                                        label: Text('settings.locationUseDevice'.tr()),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      key: ValueKey('tz_$_tz'),
                                      initialValue: _tz.isEmpty ? UserLocalePrefs.deviceTimezoneDetect() : _tz,
                                      dropdownColor: const Color(0xFF18181B),
                                      style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 14),
                                      decoration: _fieldDecoration('settings.locationFieldTimezone'.tr()),
                                      items: [
                                        if (_tz.isNotEmpty && !kCommonTimezones.contains(_tz)) DropdownMenuItem(value: _tz, child: Text(_tz)),
                                        ...kCommonTimezones.map((tz) => DropdownMenuItem(value: tz, child: Text(tz))),
                                      ],
                                      onChanged: (v) async {
                                        if (v == null) return;
                                        setState(() => _tz = v);
                                        await _run(_tzPrefsSave);
                                      },
                                    ),
                                    if (!_locationManualExpanded) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: _busy ? null : () => setState(() => _locationManualExpanded = true),
                                          child: Text('settings.locationEditManually'.tr()),
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        key: ValueKey('city_$_locationCity'),
                                        initialValue: _locationCity,
                                        style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 14),
                                        decoration: _fieldDecoration('settings.locationFieldCity'.tr()),
                                        onChanged: (v) => _locationCity = v,
                                        onFieldSubmitted: (_) => _run(_locationManualSave),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        key: ValueKey('region_$_locationRegion'),
                                        initialValue: _locationRegion,
                                        style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 14),
                                        decoration: _fieldDecoration('settings.locationFieldRegion'.tr()),
                                        onChanged: (v) => _locationRegion = v,
                                        onFieldSubmitted: (_) => _run(_locationManualSave),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        key: ValueKey('country_$_locationCountry'),
                                        initialValue: _locationCountry,
                                        style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 14),
                                        decoration: _fieldDecoration('settings.locationFieldCountry'.tr()),
                                        onChanged: (v) => _locationCountry = v,
                                        onFieldSubmitted: (_) => _run(_locationManualSave),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'settings.locationHint'.tr(),
                                        style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                                      ),
                                      if (source == 'ip' || source == 'device') ...[
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed: _busy ? null : () => setState(() => _locationManualExpanded = false),
                                            child: Text('settings.locationHideManual'.tr()),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _SectionLabel('settings.sectionVoice'.tr()),
                        const SizedBox(height: 8),
                        _Card(
                          child: Column(children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: DropdownButtonFormField<String>(
                                key: ValueKey(_speechLang),
                                initialValue: _speechLang,
                                dropdownColor: const Color(0xFF18181B),
                                style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 14),
                                decoration: _fieldDecoration('Language'),
                                selectedItemBuilder: (ctx) => speechLangOptions.map((lang) => _SpeechLangDropdownRow(lang: lang)).toList(),
                                items: speechLangOptions.map((lang) => DropdownMenuItem(value: lang, child: _SpeechLangDropdownRow(lang: lang))).toList(),
                                onChanged: (v) => v != null ? VoicePrefs.instance.setSpeechLang(v) : null,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: DropdownButtonFormField<String>(
                                key: ValueKey('mic_${VoicePrefs.instance.micDeviceId}_${_resolvedDefaultMic?.id}_${_audioInputDevices.length}'),
                                initialValue: VoicePrefs.instance.micDeviceId.isNotEmpty &&
                                        _audioInputDevices.any((d) => d.id == VoicePrefs.instance.micDeviceId)
                                    ? VoicePrefs.instance.micDeviceId
                                    : '',
                                dropdownColor: const Color(0xFF18181B),
                                style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 14),
                                decoration: _fieldDecoration('Microphone'),
                                isExpanded: true,
                                selectedItemBuilder: (ctx) => [
                                  Row(children: [
                                    const Icon(Icons.settings_suggest_outlined, size: 18, color: Color(0xFFA1A1AA)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'System default (${_resolvedDefaultMic?.label ?? "Microphone"})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ]),
                                  ..._audioInputDevices.map((d) => Row(children: [
                                    const Icon(Icons.mic_none_rounded, size: 18, color: Color(0xFFA1A1AA)),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(d.label.isNotEmpty ? d.label : d.id, overflow: TextOverflow.ellipsis)),
                                  ])),
                                ],
                                items: [
                                  DropdownMenuItem(
                                    value: '',
                                    child: Row(children: [
                                      const Icon(Icons.settings_suggest_outlined, size: 18, color: Color(0xFFA1A1AA)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'System default (${_resolvedDefaultMic?.label ?? "Microphone"})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ]),
                                  ),
                                  ..._audioInputDevices.map((d) => DropdownMenuItem(
                                    value: d.id,
                                    child: Row(children: [
                                      const Icon(Icons.mic_none_rounded, size: 18, color: Color(0xFFA1A1AA)),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(d.label.isNotEmpty ? d.label : d.id, overflow: TextOverflow.ellipsis)),
                                    ]),
                                  )),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  if (v.isEmpty) {
                                    VoicePrefs.instance.setMicDevice('', '');
                                  } else {
                                    final d = _audioInputDevices.firstWhere((x) => x.id == v);
                                    VoicePrefs.instance.setMicDevice(d.id, d.label);
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Row(children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey(_sttEngine),
                                    initialValue: _sttEngine,
                                    dropdownColor: const Color(0xFF18181B),
                                    style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 14),
                                    decoration: _fieldDecoration('Speech to text'),
                                    selectedItemBuilder: (ctx) => const [
                                      Row(children: [
                                        Icon(Icons.cloud_outlined, size: 18, color: Color(0xFFA1A1AA)),
                                        SizedBox(width: 10),
                                        Text('Cloud'),
                                      ]),
                                    ],
                                    items: const [
                                      DropdownMenuItem(value: 'cloud', child: Row(children: [
                                        Icon(Icons.cloud_outlined, size: 18, color: Color(0xFFA1A1AA)),
                                        SizedBox(width: 10),
                                        Text('Cloud'),
                                      ])),
                                    ],
                                    onChanged: (v) => v != null ? VoicePrefs.instance.setSttEngine(v) : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                uiIconButton(icon: const Icon(Icons.hearing_rounded, color: _accent), tooltip: 'Test speech to text', onPressed: () => showDialog<void>(context: context, builder: (ctx) => _SttTestDialog(speechLang: _speechLang, chatConn: widget.chatConn))),
                              ]),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Row(children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey(_ttsEngine),
                                    initialValue: _ttsEngine,
                                    dropdownColor: const Color(0xFF18181B),
                                    style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 14),
                                    decoration: _fieldDecoration('Text to speech'),
                                    selectedItemBuilder: (ctx) => const [
                                      Row(children: [
                                        Icon(Icons.cloud_outlined, size: 18, color: Color(0xFFA1A1AA)),
                                        SizedBox(width: 10),
                                        Text('Cloud'),
                                      ]),
                                    ],
                                    items: const [
                                      DropdownMenuItem(value: 'cloud', child: Row(children: [
                                        Icon(Icons.cloud_outlined, size: 18, color: Color(0xFFA1A1AA)),
                                        SizedBox(width: 10),
                                        Text('Cloud'),
                                      ])),
                                    ],
                                    onChanged: (v) => v != null ? VoicePrefs.instance.setTtsEngine(v) : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                uiIconButton(icon: const Icon(Icons.record_voice_over_rounded, color: _accent), tooltip: 'Test text to speech', onPressed: () => showDialog<void>(context: context, builder: (ctx) => _TtsTestDialog(speechLang: _speechLang, chatConn: widget.chatConn))),
                              ]),
                            ),
                            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Speech speed', style: TextStyle(color: Color(0xFFE4E4E7), fontSize: 13, fontWeight: FontWeight.w500)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)), child: Text('${_speechRate.toStringAsFixed(2)}x', style: const TextStyle(color: _accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)))])),
                            SliderTheme(data: SliderTheme.of(context).copyWith(activeTrackColor: _accent, inactiveTrackColor: const Color(0xFF27272A), thumbColor: const Color(0xFFF4F4F5), trackHeight: 3), child: Slider(value: _speechRate.clamp(0.75, 2.0), min: 0.75, max: 2.0, divisions: 25, onChanged: VoicePrefs.instance.setSpeechRate)),
                            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Speech pitch', style: TextStyle(color: Color(0xFFE4E4E7), fontSize: 13, fontWeight: FontWeight.w500)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)), child: Text('${_speechPitch.toStringAsFixed(2)}x', style: const TextStyle(color: _accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)))])),
                            SliderTheme(data: SliderTheme.of(context).copyWith(activeTrackColor: _accent, inactiveTrackColor: const Color(0xFF27272A), thumbColor: const Color(0xFFF4F4F5), trackHeight: 3), child: Slider(value: _speechPitch.clamp(0.5, 1.5), min: 0.5, max: 1.5, divisions: 20, onChanged: VoicePrefs.instance.setSpeechPitch)),
                            const SizedBox(height: 4),
                          ]),
                        ),
                        const SizedBox(height: 24),
                        Center(child: Text(appVersionLabel(), style: const TextStyle(color: Color(0xFF52525B), fontSize: 12))),
                        const SizedBox(height: 4),
                        Center(
                          child: GestureDetector(
                            onTap: serverHostPickerVisible() ? _cycleHost : null,
                            child: Text(_serverLabel, style: const TextStyle(color: Color(0xFF3F3F46), fontSize: 11)),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ProfileTapRow extends StatelessWidget {
  const _ProfileTapRow({required this.label, required this.child, this.onTap});
  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$label: ', style: const TextStyle(color: Color(0xFF71717A), fontSize: 13)), Expanded(child: child)]),
          ),
        ),
      );
}

class _ProfileTextDialog extends StatefulWidget {
  const _ProfileTextDialog({required this.title, required this.label, required this.initial, required this.onSubmit});
  final String title;
  final String label;
  final String initial;
  final String? Function(String value) onSubmit;
  @override
  State<_ProfileTextDialog> createState() => _ProfileTextDialogState();
}

class _ProfileTextDialogState extends State<_ProfileTextDialog> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final value = widget.onSubmit(_ctrl.text);
    if (value == null) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: Text(widget.title, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(controller: _ctrl, autofocus: true, style: const TextStyle(color: Color(0xFFF4F4F5)), decoration: InputDecoration(labelText: widget.label, labelStyle: const TextStyle(color: Color(0xFF71717A))), onSubmitted: (_) => _submit()),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: _submit, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black), child: const Text('Save'))],
      );
}

class _AlienIdDialog extends StatefulWidget {
  const _AlienIdDialog({required this.initial});
  final String initial;
  @override
  State<_AlienIdDialog> createState() => _AlienIdDialogState();
}

class _ReferralCodeDialog extends StatefulWidget {
  const _ReferralCodeDialog({required this.auth});
  final AuthService auth;
  @override
  State<_ReferralCodeDialog> createState() => _ReferralCodeDialogState();
}

class _ReferralCodeDialogState extends State<_ReferralCodeDialog> {
  var _code = '';
  var _codeValid = false;
  var _busy = false;
  String? _error;

  void _onReferralChanged(InReferralCodeState s) => setState(() {
        _code = s.codeNorm;
        _codeValid = s.codeValid;
        _error = null;
      });

  Future<void> _claim() async {
    if (!_codeValid || _code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await widget.auth.claimReferral(_code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claimed Rp ${(res['bonus_idr'] ?? 10000).toInt()} bonus from ${res['issuer_name'] ?? 'Referrer'}!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = uiAuthError(e);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF27272A))),
        title: const Text('Set Referral Code', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Get Rp 10.000 when you link a valid referral code.',
                style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              InReferralCode(labelText: 'Referral Code', autofocus: true, onChanged: _onReferralChanged),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: (_codeValid && !_busy) ? _claim : null,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
            child: _busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Claim Rp 10.000'),
          ),
        ],
      );
}

class _AlienIdDialogState extends State<_AlienIdDialog> {
  var _valid = false;
  late String _value = widget.initial;
  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF27272A))),
        title: Text(widget.initial.isEmpty ? 'Set Alien ID' : 'Change Alien ID', style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 360,
          child: InAlienIdSignup(
            initial: widget.initial,
            onChanged: (v) => _value = v,
            onValidChanged: (v) => setState(() => _valid = v),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: _valid ? () => Navigator.pop(context, alienIdSignupNorm(_value)) : null,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
            child: const Text('Save'),
          ),
        ],
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label, style: const TextStyle(color: Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8));
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(color: const Color(0xFF18181B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF27272A))), clipBehavior: Clip.antiAlias, child: child);
}

class _SpeechLangDropdownRow extends StatelessWidget {
  const _SpeechLangDropdownRow({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    final flag = speechLangFlag(lang);
    return Row(children: [
      if (flag != null)
        UiImg(src: flag, width: 18, height: 18, recolor: false)
      else
        const Icon(Icons.translate_rounded, size: 18, color: Color(0xFF71717A)),
      const SizedBox(width: 10),
      Text(speechLangLabel(lang), style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 14)),
    ]);
  }
}

class _TtsTestDialog extends StatefulWidget {
  const _TtsTestDialog({required this.speechLang, this.chatConn});
  final String speechLang;
  final ChatConn? chatConn;
  @override
  State<_TtsTestDialog> createState() => _TtsTestDialogState();
}

class _TtsTestDialogState extends State<_TtsTestDialog> {
  late final TextEditingController _ctrl = TextEditingController(text: 'Hello! This is a test of text to speech.');
  var _playing = false;
  @override
  void initState() {
    super.initState();
    if (widget.chatConn != null) {
      TtsService.instance.bindVoiceApi(VoiceApi(widget.chatConn!));
    }
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF27272A))),
        title: const Text('Test text to speech', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(width: 360, child: TextField(controller: _ctrl, maxLines: 3, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 14), decoration: InputDecoration(hintText: 'Enter text to read aloud…', hintStyle: const TextStyle(color: Color(0xFF71717A)), contentPadding: const EdgeInsets.all(12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF27272A)))))),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
              onPressed: _playing ? null : () async {
                final txt = _ctrl.text.trim();
                if (txt.isEmpty) return;
                setState(() => _playing = true);
                await TtsService.instance.speak(txt, lang: widget.speechLang == kSpeechLangAuto ? null : widget.speechLang);
                if (mounted) setState(() => _playing = false);
              },
              child: Text(_playing ? 'Playing…' : 'Speak'),
            ),
          ),
        ],
      );
}

class _SttTestDialog extends StatefulWidget {
  const _SttTestDialog({required this.speechLang, this.chatConn});
  final String speechLang;
  final ChatConn? chatConn;
  @override
  State<_SttTestDialog> createState() => _SttTestDialogState();
}

class _SttTestDialogState extends State<_SttTestDialog> {
  var _recording = false;
  var _isFinalizing = false;
  String _transcript = '';
  InputDevice? _activeMic;

  @override
  void initState() {
    super.initState();
    if (widget.chatConn != null) {
      final api = VoiceApi(widget.chatConn!);
      SttService.instance.bindVoiceApi(api);
      TtsService.instance.bindVoiceApi(api);
    }
    SttService.instance.liveTranscript.addListener(_onLiveTranscript);
    SttService.instance.isLiveInterim.addListener(_onInterimStateChanged);
    unawaited(SttService.instance.resolveActiveMicDevice().then((mic) {
      if (mounted) setState(() => _activeMic = mic);
    }));
  }

  void _onInterimStateChanged() {
    if (mounted) setState(() {});
  }

  void _onLiveTranscript() {
    final live = SttService.instance.liveTranscript.value.trim();
    if (mounted && live.isNotEmpty) {
      setState(() {
        _transcript = live;
      });
    }
  }

  Future<void> _stop() async {
    if (!_recording) return;
    final hadInterim = _transcript.isNotEmpty && _transcript != 'Transcribing…';
    setState(() {
      _recording = false;
      _isFinalizing = true;
      if (!hadInterim) {
        _transcript = 'Transcribing…';
      }
    });
    final text = await SttService.instance.stopAndTranscribe(lang: widget.speechLang);
    if (!mounted) return;
    setState(() {
      _isFinalizing = false;
      _transcript = text ?? (hadInterim ? _transcript : (SttService.instance.lastTranscribeError ?? 'No speech detected'));
    });
  }

  @override
  void dispose() {
    SttService.instance.liveTranscript.removeListener(_onLiveTranscript);
    SttService.instance.isLiveInterim.removeListener(_onInterimStateChanged);
    SttService.instance.onAutoStop = null;
    if (_recording || SttService.instance.isRecording.value) {
      unawaited(SttService.instance.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInterim = (_recording && SttService.instance.isLiveInterim.value) || _isFinalizing;

    return AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF27272A))),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Test speech to text', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.mic_none_rounded, size: 14, color: Color(0xFF71717A)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  VoicePrefs.instance.micDeviceId.isNotEmpty && VoicePrefs.instance.micDeviceLabel.isNotEmpty
                      ? VoicePrefs.instance.micDeviceLabel
                      : 'System default (${_activeMic?.label ?? "Windows default"})',
                  style: const TextStyle(color: Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: () async {
            if (_recording) {
              await _stop();
            } else {
              final messenger = ScaffoldMessenger.maybeOf(context);
              SttService.instance.onAutoStop = () {
                if (mounted && _recording) unawaited(_stop());
              };
              final ok = await SttService.instance.startRecording();
              if (!mounted) return;
              if (!ok) {
                SttService.instance.onAutoStop = null;
                messenger?.showSnackBar(SnackBar(content: Text(SttService.instance.lastStartError ?? sttMicErrorMessage())));
                return;
              }
              setState(() { _recording = true; _transcript = ''; });
            }
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _recording ? const Color(0xFFEF4444).withValues(alpha: 0.15) : const Color(0xFF34D399).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _recording ? const Color(0xFFEF4444) : const Color(0xFF34D399), width: 2),
            ),
            child: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded, color: _recording ? const Color(0xFFEF4444) : const Color(0xFF34D399), size: 32),
          ),
        ),
        if (_recording)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: ValueListenableBuilder<List<double>>(
              valueListenable: SttService.instance.amplitudeHistory,
              builder: (context, history, _) {
                final bars = history.length > 24 ? history.sublist(history.length - 24) : history;
                return SizedBox(
                  height: 18,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final h in bars)
                        Container(
                          width: 3,
                          height: (h * 16).clamp(3.0, 16.0),
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34D399).withValues(alpha: (h * 0.8 + 0.25).clamp(0.25, 1.0)),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 10),
        Text(
          _recording
              ? 'Listening… (speak or tap to stop)'
              : _isFinalizing
                  ? 'Finalizing transcription…'
                  : 'Tap mic to record',
          style: TextStyle(
            color: _recording
                ? const Color(0xFFEF4444)
                : _isFinalizing
                    ? const Color(0xFF34D399)
                    : const Color(0xFF71717A),
            fontSize: 13,
          ),
        ),
        if (_recording || _transcript.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF09090B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isInterim ? const Color(0xFF3F3F46) : const Color(0xFF27272A),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      isInterim ? Icons.graphic_eq_rounded : Icons.check_circle_outline_rounded,
                      size: 13,
                      color: isInterim ? const Color(0xFFA1A1AA) : const Color(0xFF34D399),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isInterim ? 'Live Interim' : 'Confirmed',
                      style: TextStyle(
                        color: isInterim ? const Color(0xFFA1A1AA) : const Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: isInterim ? FontWeight.normal : FontWeight.w600,
                        fontStyle: isInterim ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    const Spacer(),
                    if (_isFinalizing)
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF34D399))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _transcript.isNotEmpty
                      ? (_transcript + (isInterim && _recording ? ' …' : ''))
                      : 'Listening for speech…',
                  style: TextStyle(
                    color: _transcript.isNotEmpty
                        ? (isInterim ? const Color(0xFFA1A1AA) : const Color(0xFFF4F4F5))
                        : const Color(0xFF71717A),
                    fontSize: 13,
                    fontStyle: isInterim ? FontStyle.italic : FontStyle.normal,
                    fontWeight: isInterim ? FontWeight.w400 : FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ]),
    );
  }
}
