unit Main;

interface

uses
  // Delphi
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics,
  FMX.Dialogs, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Edit, FMX.ListBox, FMX.Styles,
  Winapi.Windows, Winapi.Messages, Vcl.Dialogs, System.IOUtils, DateUtils,
  System.Rtti, FMX.Platform, FMX.Surfaces, FMX.Objects,
  // Third-party
  DosCommand,
  // My
  ProjectConstants, ConfigUnit, ShellKnownPath, SettingsForm;

type
  TYTProgress = record
    downloadedBytes: Int64;
    totalBytes: Int64;
    speed: Double;
    eta: Int64;
    etaFormatted: string;
  end;

type
  TfrmMain = class(TForm)
    S: TScrollBox;
    Layout1: TLayout;
    lblTitle: TLabel;
    btnSettings: TButton;
    swchBigUI: TSwitch;
    lblSwchBigUI: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    btnPaste: TButton;
    memoUrls: TMemo;
    Label5: TLabel;
    btnSelectDownloadDir: TButton;
    edtDownloadDir: TEdit;
    Label6: TLabel;
    comboBoxResolution: TComboBox;
    swchPlaylist: TSwitch;
    Label7: TLabel;
    swchOnlyAudio: TSwitch;
    Label8: TLabel;
    swchAutoPlstFolders: TSwitch;
    Label9: TLabel;
    btnDownload: TButton;
    btnCancel: TButton;
    memoLogs: TMemo;
    btnSaveLogs: TButton;
    MaterialOxfordBlueSB: TStyleBook;
    Layout2: TLayout;
    Layout3: TLayout;
    Layout4: TLayout;
    Layout5: TLayout;
    btnClearUrls: TButton;
    Layout6: TLayout;
    Layout7: TLayout;
    mainLayout: TLayout;
    Splitter1: TSplitter;
    dscmndYTDL: TDosCommand;
    dscmndPlaylistNameGet: TDosCommand;
    indicator: TCircle;
    lblInstanceNumber: TLabel;
    lblErrorsNumber: TLabel;
    tmrMemoLogsFlush: TTimer;
    Layout8: TLayout;
    swchLogsAutoScroll: TSwitch;
    Label1: TLabel;
    procedure btnSettingsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure swchBigUISwitch(Sender: TObject);
    procedure btnPasteClick(Sender: TObject);
    procedure btnSaveLogsClick(Sender: TObject);
    procedure btnSelectDownloadDirClick(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure dscmndPlaylistNameGetTerminated(Sender: TObject);
    procedure dscmndYTDLNewLine(ASender: TObject; const ANewLine: string;
      AOutputType: TOutputType);
    procedure dscmndYTDLTerminated(Sender: TObject);
    procedure btnClearUrlsClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tmrMemoLogsFlushTimer(Sender: TObject);
    procedure swchLogsAutoScrollSwitch(Sender: TObject);

  private
    { Private declarations }
    FInstanceMutexHandle: THandle;
    FInstanceNumber: Integer;
    procedure downloadInstanceFinished();
    procedure downloadFinished();
    procedure downloadNext();
    procedure downloadNextYTDLP();
    procedure resetDownload();
    procedure updBigUI();
    procedure readConfigFile();
    procedure writeConfigFile();
    procedure updateSettingsFromForm();
    procedure updateFormFromSettings();
    procedure updateIndicator();
    procedure log(message: string);
    procedure flushLogs();
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  frmSettings: TfrmSettings;
  downloadErrors: TArray<string>;
  currentUrlProcessingIndex: Integer;
  currentUrlLaunchString: string;
  currentUrlPlaylistName: string;
  normalizedUrls: TArray<string>;
  canceling: Boolean;
  settings: TSettings;
  lastLogTime: TTime;
  logsBuffer: TArray<string>;

implementation

{$R *.fmx}

procedure TfrmMain.readConfigFile();
begin
  settings := LoadSettingsFromFile(FILE_CONFIG);
  updateFormFromSettings();
end;

procedure TfrmMain.writeConfigFile();
begin
  SaveSettingsToFile(settings, FILE_CONFIG);
end;

procedure TfrmMain.updateSettingsFromForm();
begin
  settings.bigUi := swchBigUI.IsChecked;
  settings.downloadDir := Trim(edtDownloadDir.Text);
  settings.videoResolutionIndex := comboBoxResolution.ItemIndex;
  settings.downloadPlaylist := swchPlaylist.IsChecked;
  settings.downloadMP3 := swchOnlyAudio.IsChecked;
  settings.createPlaylistDirs := swchAutoPlstFolders.IsChecked;
  settings.logsAutoScroll := swchLogsAutoScroll.IsChecked;
  writeConfigFile();
end;

procedure TfrmMain.updateFormFromSettings();
begin
  swchBigUI.IsChecked := settings.bigUi;
  edtDownloadDir.Text := settings.downloadDir;
  comboBoxResolution.ItemIndex := settings.videoResolutionIndex;
  swchPlaylist.IsChecked := settings.downloadPlaylist;
  swchOnlyAudio.IsChecked := settings.downloadMP3;
  swchAutoPlstFolders.IsChecked := settings.createPlaylistDirs;
  swchLogsAutoScroll.IsChecked := settings.logsAutoScroll;
end;

procedure TfrmMain.btnSettingsClick(Sender: TObject);
begin
  Application.CreateForm(TfrmSettings, frmSettings);
  frmSettings.Show;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  i: Integer;
  instancesI: Integer;
  mutexName: string;
begin
  FInstanceNumber := 0;
  FInstanceMutexHandle := 0;

  // Перебираем возможные номера, пока не найдём свободный
  for instancesI := 1 to MAX_INSTANCES do
  begin
    mutexName := BASE_MUTEX_NAME + IntToStr(instancesI);
    // Пытаемся создать мьютекс. Если он уже существует, CreateMutex вернёт его дескриптор,
    // а GetLastError будет равен ERROR_ALREADY_EXISTS.
    FInstanceMutexHandle := CreateMutex(nil, False, PChar(mutexName));
    if FInstanceMutexHandle = 0 then
      RaiseLastOSError; // Непредвиденная ошибка при создании

    if GetLastError = ERROR_ALREADY_EXISTS then
    begin
      // Номер занят – закрываем полученный дескриптор и пробуем следующий
      CloseHandle(FInstanceMutexHandle);
      FInstanceMutexHandle := 0;
      Continue;
    end
    else
    begin
      // Успешно создали новый мьютекс – этот номер наш
      FInstanceNumber := instancesI;
      Break;
    end;
  end;

  if FInstanceNumber = 0 then
  begin
    // Свободных номеров нет – показываем сообщение и завершаем работу
    ShowMessage('Достигнуто максимальное количество запущенных экземпляров (' +
      IntToStr(MAX_INSTANCES) + ').');
    Application.Terminate;
    Exit;
  end;

  TStyleManager.SetStyle(MaterialOxfordBlueSB.Style);

  lblInstanceNumber.Text := 'Инстанция #' + IntToStr(FInstanceNumber);
  frmMain.Caption := APP_NAME + ' - Инстанция #' + IntToStr(FInstanceNumber);
  lblTitle.Text := APP_LBL_TITLE;
  lblSwchBigUI.Text := 'UI x' + BIG_UI_MUL.ToString();

  log('[INFO] Запуск. Инстанция #' + IntToStr(FInstanceNumber));
  flushLogs();

  settings := defaultSettings;
  settings.downloadDir := TShellKnownPath.GetFolderPath(FOLDERID_Downloads);

  if not DirectoryExists(FILE_DIR) then
    CreateDir(FILE_DIR);
  for i := Low(videoResolutions) to High(videoResolutions) do
    comboBoxResolution.Items.Add(videoResolutions[i].ToString());

  if FileExists(FILE_CONFIG) then
  begin
    try
      readConfigFile();
    except
      if MessageDlg
        ('Что-то пошло не так при чтении настроек из файла. Удалить и пересоздать файл настроек?',
        mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes then
      begin
        ShowMessage('yep');
        DeleteFile(FILE_CONFIG);
        writeConfigFile();
      end;
    end;
  end
  else
  begin
    writeConfigFile();
  end;

  updateFormFromSettings();
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if FInstanceMutexHandle <> 0 then
    CloseHandle(FInstanceMutexHandle);
end;

function GetNormalizedURLs(const urlsString: string): TArray<string>;
var
  i: Integer;
  linesFromInput, clearedLines: TArray<string>;
begin
  linesFromInput := TArray<string>.Create();
  linesFromInput := urlsString.Split([sLineBreak]);
  clearedLines := TArray<string>.Create();
  for i := 0 to Length(linesFromInput) - 1 do
  begin
    if not(linesFromInput[i].Trim().Length = 0) then
    begin
      Insert([linesFromInput[i].Trim()], clearedLines, High(clearedLines) + 1);
    end;
  end;
  Result := clearedLines;
end;

function JoinURLs(const urlsString: string): string;
begin
  Result := '"' + String.Join('" "', GetNormalizedURLs(urlsString)) + '"';
end;

procedure TfrmMain.log(message: string);
begin
  logsBuffer := logsBuffer + [message];
end;

procedure TfrmMain.flushLogs();
begin
  memoLogs.Lines.AddStrings(logsBuffer);
  logsBuffer := [];
  if settings.logsAutoScroll then
  begin
    memoLogs.ScrollTo(0, memoLogs.ContentSize.Size.cy);
  end;
end;

procedure TfrmMain.tmrMemoLogsFlushTimer(Sender: TObject);
begin
  flushLogs();
end;

procedure TfrmMain.updBigUI();
begin
  if settings.bigUi then
  begin
    mainLayout.Scale.X := BIG_UI_MUL;
    mainLayout.Scale.Y := BIG_UI_MUL;
    // ScaleForPPI(GetDpiForWindow(Application.Handle) + BIGUI_DPI_ADD);
    frmMain.WindowState := TWindowState.wsMaximized;
  end
  else
  begin
    mainLayout.Scale.X := 1;
    mainLayout.Scale.Y := 1;
    // ScaleForCurrentDPI();
    frmMain.WindowState := TWindowState.wsNormal;
  end
end;

procedure TfrmMain.swchBigUISwitch(Sender: TObject);
begin
  settings.bigUi := swchBigUI.IsChecked;
  writeConfigFile();
  updBigUI();
  // do not run in formInit or UpdateFormFromSettings, because when setting .IsChecked - TfrmMain.swchBigUIClick runs automatically O_O
end;

procedure TfrmMain.swchLogsAutoScrollSwitch(Sender: TObject);
begin
  settings.logsAutoScroll := swchLogsAutoScroll.IsChecked;
  writeConfigFile();
end;

procedure TfrmMain.btnPasteClick(Sender: TObject);

var
  Svc: IFMXClipboardService;
  Value: TValue;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, Svc)
  then
  begin
    Value := Svc.GetClipboard;
    if not Value.IsEmpty then
    begin
      if Value.IsType<string> then
      begin
        memoUrls.Lines.Add(Value.ToString);
      end
    end;
  end;

  memoUrls.Lines.Add('');

  memoUrls.ScrollTo(0, memoUrls.ContentSize.Size.cy);
end;

procedure TfrmMain.btnSaveLogsClick(Sender: TObject);
var
  logsFileName: string;
begin
  if not DirectoryExists(FILE_LOGS_DIR) then
    CreateDir(FILE_LOGS_DIR);

  logsFileName := Date.Now().ToISO8601(False).Replace(':', '_') + '.txt';

  TFile.AppendAllText(FILE_LOGS_DIR + '\' + logsFileName,
    memoLogs.Text + String.Join(sLineBreak, logsBuffer));
end;

procedure TfrmMain.btnSelectDownloadDirClick(Sender: TObject);
begin
  with TFileOpenDialog.Create(nil) do
    try
      Options := [fdoPickFolders];
      if Execute then
      begin
        settings.downloadDir := FileName;
        edtDownloadDir.Text := settings.downloadDir;
      end;
    finally
      Free
    end;
end;

procedure TfrmMain.downloadInstanceFinished();
begin
  log('[INFO] Одна из инстанций yt-dlp завершила работу');
  currentUrlProcessingIndex := currentUrlProcessingIndex + 1;
  if ((currentUrlProcessingIndex > High(normalizedUrls))) then
  begin
    downloadFinished();
  end
  else
  begin
    if not canceling then
      downloadNext();
  end;
end;

procedure TfrmMain.updateIndicator();
begin
  indicator.Visible := True;

  if Length(downloadErrors) > 0 then
  begin
    indicator.fill.Color := TAlphaColors.Red;
  end
  else
  begin
    indicator.fill.Color := TAlphaColors.Green;
  end;

  lblErrorsNumber.Text := Length(downloadErrors).ToString();
end;

procedure TfrmMain.downloadFinished();
var
  i: Integer;
begin
  log('[INFO] СКАЧИВАНИЕ ЗАВЕРШЕНО');

  if Length(downloadErrors) > 0 then
  begin
    log('[INFO] ВО ВРЕМЯ СКАЧИВАНИЯ ПРОИЗОШЛИ ОШИБКИ:');
    for i := Low(downloadErrors) to High(downloadErrors) do
    begin
      log(downloadErrors[i]);
    end;
    log('[INFO] АХТУНГ!!! СКАЧИВАНИЕ ЗАВЕРШЕНО С ОШИБКАМИ');
  end;

  btnDownload.Enabled := True;

  updateIndicator();
end;

procedure TfrmMain.downloadNext();
begin
  log('[INFO] Началась обработка URL №' + (currentUrlProcessingIndex + 1)
    .ToString() + ': ' + normalizedUrls[currentUrlProcessingIndex]);
  if settings.createPlaylistDirs and settings.downloadPlaylist and
    normalizedUrls[currentUrlProcessingIndex].Contains('list') then
  begin
    log('[INFO] Получение названия плейлиста...');
    dscmndPlaylistNameGet.CommandLine := FILE_YTDLP +
      ' -I 1:1 --skip-download --no-warning --print playlist_title "' +
      normalizedUrls[currentUrlProcessingIndex] + '"';
    dscmndPlaylistNameGet.Execute();
  end
  else
  begin
    downloadNextYTDLP();
  end;
end;

procedure TfrmMain.downloadNextYTDLP();
begin
  currentUrlLaunchString := FILE_YTDLP;
  currentUrlLaunchString := currentUrlLaunchString + ' --ignore-errors';
  // currentUrlLaunchString := currentUrlLaunchString + ' --restrict-filenames';
  if not settings.downloadPlaylist then
    currentUrlLaunchString := currentUrlLaunchString + ' --no-playlist';
  currentUrlLaunchString := currentUrlLaunchString + ' --ffmpeg-location ' +
    FILE_FFMPEG_DIR;
  if settings.createPlaylistDirs and settings.downloadPlaylist and
    normalizedUrls[currentUrlProcessingIndex].Contains('list') then
  begin
    // Temporary
    // currentUrlPlaylistName := 'playlist' + (currentUrlProcessingIndex + 1).ToString();

    CreateDir(settings.downloadDir + '\' + currentUrlPlaylistName);
    currentUrlLaunchString := currentUrlLaunchString + ' --paths home:' + '"' +
      StringReplace(settings.downloadDir, '\', '\\', [rfReplaceAll]) + '\\' +
      currentUrlPlaylistName + '"';
  end
  else
  begin
    currentUrlLaunchString := currentUrlLaunchString + ' --paths home:' + '"' +
      StringReplace(settings.downloadDir, '\', '\\', [rfReplaceAll]) + '"';
  end;
  currentUrlLaunchString := currentUrlLaunchString +
    ' --replace-in-metadata "title" "[\/\\\:\*\"\?\<\>\|\`'']" "_"';
  currentUrlLaunchString := currentUrlLaunchString + ' -S "res:' +
    videoResolutions[settings.videoResolutionIndex].ToString() +
    ',ext:mp4:m4a,vcodec:h264"';
  if settings.downloadMP3 then
    currentUrlLaunchString := currentUrlLaunchString +
      ' -f "bestaudio/best" -x --audio-format mp3 --audio-quality 192';
  if settings.downloadPlaylist then
  begin
    currentUrlLaunchString := currentUrlLaunchString +
      ' -o "%(playlist_index&[{}] |)s%(title).80s [%(id)s].%(ext)s"';
  end
  else
  begin
    currentUrlLaunchString := currentUrlLaunchString +
      ' -o "%(title).120s [%(id)s].%(ext)s"';
  end;

  currentUrlLaunchString := currentUrlLaunchString + ' "' + normalizedUrls
    [currentUrlProcessingIndex] + '"';

  log('EXEC: ' + currentUrlLaunchString);
  dscmndYTDL.CommandLine := currentUrlLaunchString;
  dscmndYTDL.Execute();
end;

procedure TfrmMain.resetDownload();
begin
  normalizedUrls := [];
  downloadErrors := [];
  updateIndicator();
  currentUrlProcessingIndex := 0;
end;

procedure TfrmMain.btnClearUrlsClick(Sender: TObject);
begin
  memoUrls.Lines.Clear();
end;

procedure TfrmMain.btnDownloadClick(Sender: TObject);
var
  newHistoryEntry: string;
begin
  log(Format('[INFO] СТАРТ ЗАГРУЗКИ %s', [Date.Now().ToISO8601(False)]));

  updateSettingsFromForm();

  // Check if edit box is empty
  if memoUrls.Lines.Text.Trim().IsEmpty() then
  begin
    log('[ERR] ВВЕДИТЕ АДРЕС(А)!');
    Exit;
  end;

  if not TDirectory.Exists(FILE_DIR) then
  begin
    log('Не найдена папка ' + FILE_DIR + ', создание...');
    TDirectory.CreateDirectory(FILE_DIR);
  end;

  if not TFile.Exists(FILE_YTDLP) then
  begin
    log('[ERR] Не найден yt-dlp.exe! Откройте меню настройки или вручную скачайте в '
      + FILE_YTDLP);
    Exit;
  end;

  if not TDirectory.Exists(FFMPEG_DIR) then
  begin
    log('[ERR] Не найден ffmpeg! Откройте меню настройки или вручную скачайте и распакуйте в '
      + FFMPEG_DIR);
    Exit;
  end;

  btnDownload.Enabled := False;
  canceling := False;
  resetDownload();
  indicator.Visible := False;

  normalizedUrls := GetNormalizedURLs(memoUrls.Text);

  newHistoryEntry := sLineBreak + sLineBreak + ';;;START HISTORY_V_' + APP_VER +
    ';' + sLineBreak + '#DATE ' + TDateTime.Now().ToISO8601(False) + ';' +
    sLineBreak + '#DIR ' + settings.downloadDir + ';' + sLineBreak +
    '#RESOLUTION ' + videoResolutions[settings.videoResolutionIndex].ToString()
    + ';' + sLineBreak + '#PLAYLIST ' + BoolToStr(settings.downloadPlaylist,
    True) + ';' + sLineBreak + '#MP3 ' + BoolToStr(settings.downloadMP3, True) +
    ';' + sLineBreak + '#PLAYLIST_DIRS ' +
    BoolToStr(settings.createPlaylistDirs, True) + ';' + sLineBreak + 'URLS:' +
    sLineBreak + String.Join(sLineBreak, normalizedUrls) + sLineBreak + ';;;END'
    + sLineBreak;

  TFile.AppendAllText(FILE_HISTORY, newHistoryEntry);

  currentUrlProcessingIndex := Low(normalizedUrls);
  downloadNext();
end;

procedure TfrmMain.btnCancelClick(Sender: TObject);
begin
  btnDownload.Enabled := True;
  canceling := True;
  dscmndYTDL.Stop();
  log('[INFO] ОТМЕНА ЗАГРУЗКИ');
end;

procedure TfrmMain.dscmndPlaylistNameGetTerminated(Sender: TObject);
begin
  currentUrlPlaylistName := dscmndPlaylistNameGet.Lines[0].Substring(0, 30);
  log('[INFO] Получено название плейлиста: ' + currentUrlPlaylistName);
  downloadNextYTDLP();
end;

procedure TfrmMain.dscmndYTDLNewLine(ASender: TObject; const ANewLine: string;
  AOutputType: TOutputType);
begin
  log(ANewLine);
  if ANewLine.Contains('err') or ANewLine.Contains('Err') or
    ANewLine.Contains('ERR') then
  begin
    SetLength(downloadErrors, Length(downloadErrors) + 1);
    downloadErrors[High(downloadErrors)] := ANewLine;
  end;

  // if Length(memoLogs.Lines.ToStringArray()) >= 3000 then
  // begin
  // memoLogs.Lines.Delete(0);
  // end;
end;

procedure TfrmMain.dscmndYTDLTerminated(Sender: TObject);
begin
  downloadInstanceFinished();
end;

end.
