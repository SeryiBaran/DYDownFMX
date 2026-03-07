unit SettingsForm;

interface

uses
  // Delphi
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Types,
  System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Objects,
  Winapi.WinInet, System.Zip, ShellAPI, FMX.Platform.Win,
  // Third-party
  // My
  ProjectConstants;

type
  TfrmSettings = class(TForm)
    Label1: TLabel;
    btnGetYTDLP: TButton;
    btnGetFFMPEG: TButton;
    Label2: TLabel;
    btnOpenDataDir: TButton;
    Image1: TImage;
    ScrollBox1: TScrollBox;
    procedure btnGetYTDLPClick(Sender: TObject);
    procedure btnGetFFMPEGClick(Sender: TObject);
    procedure btnOpenDataDirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

function Download(URL, User, Pass, FileName: string): Boolean;
const
  BufferSize = 1024;
var
  hSession, hURL: HInternet;
  Buffer: array [1 .. BufferSize] of Byte;
  BufferLen: DWORD;
  F: File;
begin
  Result := False;
  hSession := InternetOpen('', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);

  // Establish the secure connection
  InternetConnect(hSession, PChar(URL), INTERNET_DEFAULT_HTTPS_PORT,
    PChar(User), PChar(Pass), INTERNET_SERVICE_HTTP, 0, 0);

  try
    hURL := InternetOpenURL(hSession, PChar(URL), nil, 0, 0, 0);
    try
      AssignFile(F, FileName);
      Rewrite(F, 1);
      try
        repeat
          InternetReadFile(hURL, @Buffer, SizeOf(Buffer), BufferLen);
          BlockWrite(F, Buffer, BufferLen)
        until BufferLen = 0;
      finally
        CloseFile(F);
        Result := True;
      end;
    finally
      InternetCloseHandle(hURL)
    end
  finally
    InternetCloseHandle(hSession)
  end;
end;

procedure TfrmSettings.btnGetFFMPEGClick(Sender: TObject);
var
  zipFile: TZipFile;
begin
  if not DirectoryExists(FILE_DIR) then
    CreateDir(FILE_DIR);
  if not DirectoryExists(FILE_FFMPEG_DIR) then
    CreateDir(FILE_FFMPEG_DIR);

  if FileExists(FILE_FFMPEG_DOWNLOADED) then
    DeleteFile(FILE_FFMPEG_DOWNLOADED);
  if FileExists(FILE_FFMPEG) then
    DeleteFile(FILE_FFMPEG);

  if Download(LATEST_FFMPEG_DOWNLOAD_URL, '', '', FILE_FFMPEG_DOWNLOADED) then
  begin
    zipFile := TZipFile.Create();
    zipFile.Open(FILE_FFMPEG_DOWNLOADED, zmRead);
    zipFile.Extract(FILE_FFMPEG_DOWNLOADED_INDIR + '/bin/ffmpeg.exe',
      FILE_FFMPEG_DIR, False);
    zipFile.Free();
    DeleteFile(FILE_FFMPEG_DOWNLOADED);

    btnGetFFMPEG.Text := 'FFMPEG - ‚Ó‰Â Á‡‚Â¯ÂÌÓ';
  end
  else
  begin
    btnGetFFMPEG.Text := 'FFMPEG - Œÿ»¡ ¿ «¿√–”« »';
  end;
end;

procedure TfrmSettings.btnGetYTDLPClick(Sender: TObject);
begin
  if not DirectoryExists(FILE_DIR) then
    CreateDir(FILE_DIR);

  if FileExists(FILE_YTDLP) then
    DeleteFile(FILE_YTDLP);

  if Download(LATEST_YTDLP_DOWNLOAD_URL, '', '', FILE_YTDLP) then
  begin
    btnGetYTDLP.Text := 'YT-DLP - ‚Ó‰Â Á‡‚Â¯ÂÌÓ';
  end
  else
  begin
    btnGetYTDLP.Text := 'YT-DLP - Œÿ»¡ ¿ «¿√–”« »';
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
  Self.Caption := APP_NAME + ' - Õ‡ÒÚÓÈÍË';
end;

end.
