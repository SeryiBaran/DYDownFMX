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
    btnGetDENO: TButton;
    btnGetTTS: TButton;
    procedure btnGetYTDLPClick(Sender: TObject);
    procedure btnGetFFMPEGClick(Sender: TObject);
    procedure btnOpenDataDirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure repoLinkClick(Sender: TObject);
    procedure btnGetDENOClick(Sender: TObject);
    procedure btnGetTTSClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

function RunAsAdminAndWait(const aFile, aParams: string): Boolean;
var
  sei: TShellExecuteInfo;
  ExitCode: DWORD;
begin
  Result := False;
  FillChar(sei, SizeOf(sei), 0);
  sei.cbSize := SizeOf(sei);
  sei.fMask := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_DDEWAIT;
  sei.lpVerb := 'runas';  // Запрос прав администратора
  sei.lpFile := PChar(aFile);
  sei.lpParameters := PChar(aParams);
  sei.nShow := SW_HIDE;   // Скрываем окно

  if ShellExecuteEx(@sei) then
  begin
    // Ожидаем завершения установки
    WaitForSingleObject(sei.hProcess, INFINITE);

    // Получаем код возврата
    if GetExitCodeProcess(sei.hProcess, ExitCode) then
      Result := (ExitCode = 0);

    CloseHandle(sei.hProcess);
  end;
end;

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

procedure TfrmSettings.btnGetDENOClick(Sender: TObject);
var
  Zip: TZipFile;
  EntryName, RelPath, FolderPart, TargetFolder: string;
begin
  if not DirectoryExists(FILE_DIR) then
    CreateDir(FILE_DIR);

  if FileExists(FILE_DENO_DOWNLOADED) then
    DeleteFile(FILE_DENO_DOWNLOADED);

  if not DownloadFile(LATEST_DENO_DOWNLOAD_URL, FILE_DENO_DOWNLOADED) then
  begin
    btnGetDENO.Text := 'DENO - ОШИБКА ЗАГРУЗКИ';
    Exit;
  end;

  Zip := TZipFile.Create;
  try
    Zip.Open(FILE_DENO_DOWNLOADED, zmRead);

    Zip.Extract(FILE_DENO_EXENAME, FILE_DIR, False);

    Zip.Close;
  finally
    Zip.Free;
  end;

  btnGetDENO.Text := 'DENO - вроде завершено';
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

procedure TfrmSettings.btnGetTTSClick(Sender: TObject);
var
  Zip: TZipFile;
  EntryName, DestFile: string;
  InstallerPath: string;
  InstallParams: string;
begin
  if not DirectoryExists(FILE_DIR) then
    CreateDir(FILE_DIR);

  //if FileExists(FILE_TTS_ZIP) then
  //  DeleteFile(FILE_TTS_ZIP);

  if FileExists(FILE_TTS_INST) then
    DeleteFile(FILE_TTS_INST);

  //if not DownloadFile(LATEST_TTS_DOWNLOAD_URL, FILE_TTS_ZIP) then
  if not DownloadFile(LATEST_TTS_DOWNLOAD_URL, FILE_TTS_INST) then
  begin
    btnGetTTS.Text := 'TTS - ОШИБКА ЗАГРУЗКИ';
    Exit;
  end;

  //Zip := TZipFile.Create;
  //try
  //  Zip.Open(FILE_TTS_ZIP, zmRead);
  //
  //  if Zip.FileCount > 0 then
  //  begin
  //    EntryName := Zip.FileName[0];               // имя первого файла в архиве
  //    DestFile := FILE_TTS_INST;
  //    Zip.Extract(EntryName, DestFile);           // извлечение сразу с нужным именем
  //  end
  //  else
  //    raise Exception.Create('Архив пуст или не содержит файлов');
  //
  //  Zip.Close;
  //finally
  //  Zip.Free;
  //end;

  InstallerPath := FILE_TTS_INST;
  InstallParams := '/S';

  if RunAsAdminAndWait(InstallerPath, InstallParams) then
    btnGetTTS.Text := 'TTS - вроде завершено'
  else
    btnGetTTS.Text := 'TTS - ОШИБКА УСТАНОВКИ';
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
