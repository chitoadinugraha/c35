; Alien AI Remote Agent (Windows) — first-install setup.
; Compile: ISCC.exe /DStageDir=... /DMyAppVersion=1.5.0 /DMyAppBuild=5 alienai_remote_windows.iss

#ifndef StageDir
  #define StageDir "."
#endif
#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif
#ifndef MyAppBuild
  #define MyAppBuild "0"
#endif

#define MyAppName "Alien AI Remote Agent"
#define MyAppPublisher "Alien AI"
#define MyAppExeName "alienai_remote_windows.exe"
#define WinFspDllName "winfsp-x64.dll"
#define WinFspMsiName "winfsp-2.1.25156.msi"
#define MyAppId "{{A7C4E2B1-9F3D-4E8A-B6C1-RemoteAgent2026}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion} ({#MyAppBuild})
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\AlienAI
DisableDirPage=yes
DisableProgramGroupPage=yes
OutputBaseFilename=AlienAI_Remote_Windows_Setup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
SetupIconFile={#StageDir}\alien_rounded.ico
UninstallDisplayName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "{#StageDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#StageDir}\{#WinFspDllName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#StageDir}\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall; Check: VCRedistNeeded
Source: "{#StageDir}\{#WinFspMsiName}"; DestDir: "{tmp}"; Flags: deleteafterinstall; Check: WinFspNeeded

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Run]
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Microsoft Visual C++ runtime..."; Flags: waituntilterminated; Check: VCRedistNeeded
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\{#WinFspMsiName}"" /quiet /norestart ADDLOCAL=ALL"; StatusMsg: "Installing WinFsp (virtual drive)..."; Flags: waituntilterminated; Check: WinFspNeeded
Filename: "netsh.exe"; Parameters: "advfirewall firewall add rule name=""AlienAI Remote Agent"" dir=in action=allow program=""{app}\{#MyAppExeName}"" enable=yes profile=any"; Flags: runhidden
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: postinstall nowait skipifsilent

[Code]
function WinFspNeeded: Boolean;
begin
  Result := not RegKeyExists(HKLM, 'SOFTWARE\WOW6432Node\WinFsp');
end;

function VCRedistNeeded: Boolean;
var
  Installed: Cardinal;
begin
  Result := False;
  if not FileExists(ExpandConstant('{sys}\vcruntime140.dll')) then
  begin
    Result := True;
    Exit;
  end;
  if RegQueryDWordValue(HKLM, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Installed', Installed) then
  begin
    if Installed <> 1 then
      Result := True;
  end;
end;
