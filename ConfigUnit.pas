unit ConfigUnit;

interface

uses
  System.SysUtils, System.IniFiles;

type
  TSettings = record
    bigUi: Boolean;
    downloadDir: string;
    videoResolutionIndex: Integer;
    downloadPlaylist: Boolean;
    downloadMP3: Boolean;
    createPlaylistDirs: Boolean;
    logsAutoScroll: Boolean;
  end;

procedure SaveSettingsToFile(const Settings: TSettings; const FileName: string);
function LoadSettingsFromFile(const FileName: string): TSettings;

implementation

const
  SECTION = 'Settings';

procedure SaveSettingsToFile(const Settings: TSettings; const FileName: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FileName);
  try
    Ini.WriteBool(SECTION, 'BigUi', Settings.bigUi);
    Ini.WriteString(SECTION, 'DownloadDir', Settings.downloadDir);
    Ini.WriteInteger(SECTION, 'VideoResolutionIndex', Settings.videoResolutionIndex);
    Ini.WriteBool(SECTION, 'DownloadPlaylist', Settings.downloadPlaylist);
    Ini.WriteBool(SECTION, 'DownloadMP3', Settings.downloadMP3);
    Ini.WriteBool(SECTION, 'CreatePlaylistDirs', Settings.createPlaylistDirs);
    Ini.WriteBool(SECTION, 'LogsAutoScroll', Settings.logsAutoScroll);
  finally
    Ini.Free;
  end;
end;

function LoadSettingsFromFile(const FileName: string): TSettings;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FileName);
  try
    Result.bigUi := Ini.ReadBool(SECTION, 'BigUi', False);
    Result.downloadDir := Ini.ReadString(SECTION, 'DownloadDir', '');
    Result.videoResolutionIndex := Ini.ReadInteger(SECTION, 'VideoResolutionIndex', 0);
    Result.downloadPlaylist := Ini.ReadBool(SECTION, 'DownloadPlaylist', False);
    Result.downloadMP3 := Ini.ReadBool(SECTION, 'DownloadMP3', False);
    Result.createPlaylistDirs := Ini.ReadBool(SECTION, 'CreatePlaylistDirs', False);
    Result.logsAutoScroll := Ini.ReadBool(SECTION, 'LogsAutoScroll', True);
  finally
    Ini.Free;
  end;
end;

end.
