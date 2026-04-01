#define MyAppName      "ChickenWire"
#define MyAppPublisher "ChickenWire"
#define MyAppExeName   "ChickenWire.exe"

; Version is passed in from the command line:
;   ISCC /DMyAppVersion=1.2.3 installer.iss
; Falls back to "0.0.0" when building locally without a tag.
#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif

[Setup]
AppId={{A7F3C2D1-84BE-4E6A-9B0F-123456789ABC}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputBaseFilename=ChickenWire-{#MyAppVersion}-windows-x64-setup
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64os
ArchitecturesAllowed=x64os
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExeName}
; Require no elevation if the user installs into their own AppData
PrivilegesRequiredOverridesAllowed=commandline dialog

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Grab everything windeployqt staged into the package\ folder
Source: "package\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\{#MyAppName}";       Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; \
  Flags: nowait postinstall skipifsilent
