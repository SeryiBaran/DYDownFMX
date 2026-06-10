unit SettingsForm;

interface

uses
  // Delphi
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Types,
  System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Objects,
  Winapi.WinInet, System.Zip, ShellAPI, FMX.Platform.Win, System.IOUtils,
  // Third-party
  // My
  ProjectConstants, fOpen;

type
  TfrmSettings = class(TForm)
    Label1: TLabel;
    btnGetYTDLP: TButton;
    btnGetFFMPEG: TButton;
    Label2: TLabel;
    btnOpenDataDir: TButton;
    Image1: TImage;
    ScrollBox1: TScrollBox;
    repoLink: TLabel;
    procedure btnGetYTDLPClick(Sender: TObject);
    procedure btnGetFFMPEGClick(Sender: TObject);
    procedure btnOpenDataDirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure repoLinkClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

function DownloadFile(const URL, FileName: string): Boolean;
const
  BufferSize = 4096;
var
  hSession, hURL: HInternet;
  Buffer: array of Byte;
  BytesRead: DWORD;
  FS: TFileStream;
begin
  Result := False;
  hSession := InternetOpen('Mozilla/5.0', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if hSession = nil then Exit;
  try
    hURL := InternetOpenURL(hSession, PChar(URL), nil, 0, 0, 0);
    if hURL = nil then Exit;
    try
      FS := TFileStream.Create(FileName, fmCreate);
      try
        SetLength(Buffer, BufferSize);
        repeat
          InternetReadFile(hURL, @Buffer[0], BufferSize, BytesRead);
          if BytesRead = 0 then Break;
          FS.WriteBuffer(Buffer[0], BytesRead);
        until False;
        Result := True;
      finally
        FS.Free;
      end;
    finally
      InternetCloseHandle(hURL);
    end;
  finally
    InternetCloseHandle(hSession);
  end;
end;

procedure TfrmSettings.btnGetFFMPEGClick(Sender: TObject);
var
  Zip: TZipFile;
  i: Integer;
  EntryName, RelPath, FolderPart, TargetFolder: string;
begin
  if not DirectoryExists(FILE_DIR) then
    CreateDir(FILE_DIR);

  if DirectoryExists(FILE_FFMPEG_DIR) then
    TDirectory.Delete(FILE_FFMPEG_DIR, True);
  CreateDir(FILE_FFMPEG_DIR);

  if FileExists(FILE_FFMPEG_DOWNLOADED) then
    DeleteFile(FILE_FFMPEG_DOWNLOADED);

  if not DownloadFile(LATEST_FFMPEG_DOWNLOAD_URL, FILE_FFMPEG_DOWNLOADED) then
  begin
    btnGetFFMPEG.Text := 'FFMPEG - ОШИБКА ЗАГРУЗКИ';
    Exit;
  end;

  Zip := TZipFile.Create;
  try
    Zip.Open(FILE_FFMPEG_DOWNLOADED, zmRead);
    for i := 0 to Zip.FileCount - 1 do
    begin
      EntryName := Zip.FileNames[i];
      if EntryName.EndsWith('/') then Continue; // пропускаем папки

      var p := Pos('/', EntryName);
      if p = 0 then Continue; // нет корневой папки – такого быть не должно
      RelPath := Copy(EntryName, p + 1, MaxInt);
      if RelPath = '' then Continue;

      // Определяем папку назначения (без имени файла)
      FolderPart := TPath.GetDirectoryName(RelPath);
      if FolderPart <> '' then
        FolderPart := StringReplace(FolderPart, '/', '\', [rfReplaceAll]);

      TargetFolder := System.IOUtils.TPath.Combine(FFMPEG_DIR, FolderPart);
      if not DirectoryExists(TargetFolder) then
        ForceDirectories(TargetFolder);

      // Извлекаем файл в папку (имя файла берётся из архива)
      Zip.Extract(i, TargetFolder, False);
    end;
    Zip.Close;
  finally
    Zip.Free;
  end;

  //DeleteFile(FILE_FFMPEG_DOWNLOADED);
  btnGetFFMPEG.Text := 'FFMPEG - вроде завершено';
end;

procedure TfrmSettings.btnGetYTDLPClick(Sender: TObject);
begin
  if not DirectoryExists(FILE_DIR) then
    CreateDir(FILE_DIR);

  if FileExists(FILE_YTDLP) then
    DeleteFile(FILE_YTDLP);

  if DownloadFile(LATEST_YTDLP_DOWNLOAD_URL, FILE_YTDLP) then
  begin
    btnGetYTDLP.Text := 'YT-DLP - вроде завершено';
  end
  else
  begin
    btnGetYTDLP.Text := 'YT-DLP - ОШИБКА ЗАГРУЗКИ';
  end;
end;

procedure TfrmSettings.btnOpenDataDirClick(Sender: TObject);
var
  Wnd: HWND;
begin
  Wnd := WindowHandleToPlatform(Self.Handle).Wnd;

  ShellExecute(Wnd, 'OPEN', 'explorer.exe', FILE_DIR, nil, SW_NORMAL)
end;

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  Self.Caption := APP_NAME + ' - Настройки';
end;

procedure TfrmSettings.repoLinkClick(Sender: TObject);
begin
  TMisc.Open(repoLink.Text);
end;

end.
