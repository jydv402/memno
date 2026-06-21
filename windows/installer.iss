#ifndef AppVersion
  #define AppVersion "1.3.2"
#endif

[Setup]
AppName=Memno
AppVersion={#AppVersion}
DefaultDirName={autopf}\Memno
DefaultGroupName=Memno
LicenseFile=..\LICENSE
OutputDir=..\build\windows\x64\runner
OutputBaseFilename=memno-windows-x64-installer
Compression=lzma
SolidCompression=yes
SetupIconFile=runner\resources\app_icon.ico
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Memno"; Filename: "{app}\memno.exe"
Name: "{userdesktop}\Memno"; Filename: "{app}\memno.exe"

[Run]
Filename: "{app}\memno.exe"; Description: "Launch Memno"; Flags: postinstall nowait skipifsilent
