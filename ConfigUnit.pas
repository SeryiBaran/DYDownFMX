unit ConfigUnit;

interface

uses System.JSON, System.IOUtils, System.SysUtils;

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

function SettingsToJSON(const settingsProp: TSettings): TJSONObject;
procedure SaveSettingsToFile(const Person: TSettings; const FileName: string);
function JSONToSettings(JSON: TJSONObject): TSettings;
function LoadSettingsFromFile(const FileName: string): TSettings;

implementation

function SettingsToJSON(const settingsProp: TSettings): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('bigUi', TJSONBool.Create(settingsProp.bigUi));
    Result.AddPair('downloadDir', settingsProp.downloadDir);
    Result.AddPair('videoResolutionIndex',
      TJSONNumber.Create(settingsProp.videoResolutionIndex));
    Result.AddPair('downloadPlaylist',
      TJSONBool.Create(settingsProp.downloadPlaylist));
    Result.AddPair('downloadMP3', TJSONBool.Create(settingsProp.downloadMP3));
    Result.AddPair('createPlaylistDirs',
      TJSONBool.Create(settingsProp.createPlaylistDirs));
    Result.AddPair('logsAutoScroll',
      TJSONBool.Create(settingsProp.logsAutoScroll));
  except
    Result.Free;
    raise;
  end;
end;

procedure SaveSettingsToFile(const Person: TSettings; const FileName: string);
var
  JSONObj: TJSONObject;
  JSONString: string;
begin
  JSONObj := SettingsToJSON(Person);
  try
    JSONString := JSONObj.Format; // Formats with indentation
    TFile.WriteAllText(FileName, JSONString, TEncoding.UTF8);
  finally
    JSONObj.Free;
  end;
end;

function JSONToSettings(JSON: TJSONObject): TSettings;
begin
  Result.bigUi := (JSON.GetValue<TJSONBool>('bigUi')).AsBoolean;
  Result.downloadDir := JSON.GetValue<string>('downloadDir');
  Result.videoResolutionIndex :=
    (JSON.GetValue<TJSONNumber>('videoResolutionIndex')).AsInt;
  Result.downloadPlaylist := (JSON.GetValue<TJSONBool>('downloadPlaylist'))
    .AsBoolean;
  Result.downloadMP3 := (JSON.GetValue<TJSONBool>('downloadMP3')).AsBoolean;
  Result.createPlaylistDirs := (JSON.GetValue<TJSONBool>('createPlaylistDirs'))
    .AsBoolean;
  Result.logsAutoScroll := (JSON.GetValue<TJSONBool>('logsAutoScroll'))
    .AsBoolean;
end;

function LoadSettingsFromFile(const FileName: string): TSettings;
var
  JSONString: string;
  JSONObj: TJSONObject;
begin
  JSONString := TFile.ReadAllText(FileName, TEncoding.UTF8);
  JSONObj := TJSONObject.ParseJSONValue(JSONString) as TJSONObject;
  try
    Result := JSONToSettings(JSONObj);
  finally
    JSONObj.Free;
  end;
end;

end.
