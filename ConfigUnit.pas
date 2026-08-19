unit ConfigUnit;

interface

uses
  System.SysUtils, System.IniFiles, ProjectConstants;

type
  TSettings = record
    bigUi: Boolean;
    downloadDir: string;
    videoResolutionIndex: Integer;
    audioBitrateIndex: Integer;
    downloadPlaylist: Boolean;
    downloadMP3: Boolean;
    downloadLOCALAUDIO: Boolean;
    createPlaylistDirs: Boolean;
    useCookies: Boolean;
    cookiesFile: string;
    logsAutoScroll: Boolean;
  end;

procedure SaveSettingsToFile(const Settings: TSettings; const FileName: string);
function LoadSettingsFromFile(const FileName: string): TSettings;

const
  defaultSettings: TSettings = (bigUi: True; downloadDir: FILE_DIR;
    videoResolutionIndex: 2; audioBitrateIndex: 1; downloadPlaylist: False; downloadMP3: False;
    downloadLOCALAUDIO: False;
    createPlaylistDirs: False; useCookies: False; cookiesFile: DEFAULT_COOKIES_FILE; logsAutoScroll: True;);

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
    Ini.WriteInteger(SECTION, 'AudioBitrateIndex', Settings.audioBitrateIndex);
    Ini.WriteBool(SECTION, 'DownloadPlaylist', Settings.downloadPlaylist);
    Ini.WriteBool(SECTION, 'DownloadMP3', Settings.downloadMP3);
    Ini.WriteBool(SECTION, 'DownloadLOCALAUDIO', Settings.downloadLOCALAUDIO);
    Ini.WriteBool(SECTION, 'CreatePlaylistDirs', Settings.createPlaylistDirs);
    Ini.WriteBool(SECTION, 'UseCookies', Settings.useCookies);
    Ini.WriteString(SECTION, 'CookiesFile', Settings.cookiesFile);
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
    Result.bigUi := Ini.ReadBool(SECTION, 'BigUi', defaultSettings.bigUi);
    Result.downloadDir := Ini.ReadString(SECTION, 'DownloadDir', defaultSettings.downloadDir);
    Result.videoResolutionIndex := Ini.ReadInteger(SECTION, 'VideoResolutionIndex', defaultSettings.videoResolutionIndex);
    Result.audioBitrateIndex := Ini.ReadInteger(SECTION, 'AudioBitrateIndex', defaultSettings.audioBitrateIndex);
    Result.downloadPlaylist := Ini.ReadBool(SECTION, 'DownloadPlaylist', defaultSettings.downloadPlaylist);
    Result.downloadMP3 := Ini.ReadBool(SECTION, 'DownloadMP3', defaultSettings.downloadMP3);
    Result.downloadLOCALAUDIO := Ini.ReadBool(SECTION, 'DownloadLOCALAUDIO', defaultSettings.downloadLOCALAUDIO);
    Result.createPlaylistDirs := Ini.ReadBool(SECTION, 'CreatePlaylistDirs', defaultSettings.createPlaylistDirs);
    Result.useCookies := Ini.ReadBool(SECTION, 'UseCookies', defaultSettings.useCookies);
    Result.cookiesFile := Ini.ReadString(SECTION, 'CookiesFile', defaultSettings.cookiesFile);
    Result.logsAutoScroll := Ini.ReadBool(SECTION, 'LogsAutoScroll', defaultSettings.logsAutoScroll);
  finally
    Ini.Free;
  end;
end;

end.
