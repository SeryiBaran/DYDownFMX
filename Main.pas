unit Main;

interface

uses
  // Delphi
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics,
  FMX.Dialogs, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Edit, FMX.ListBox, FMX.Styles,
  Winapi.Windows, Winapi.Messages, Vcl.Dialogs, System.IOUtils, DateUtils,
  System.Rtti, FMX.Platform, FMX.Surfaces, FMX.Objects, System.RegularExpressions, System.Generics.Collections,
  // Third-party
  DosCommand,
  // My
  ProjectConstants, ConfigUnit, ShellKnownPath, SettingsForm, Utils;

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
    Layout9: TLayout;
    comboBoxAudioBitrate: TComboBox;
    Label2: TLabel;
    Label8: TLabel;
    swchOnlyAudio: TSwitch;
    indicator2: TRectangle;
    lblErrorsUrls: TLabel;
    Label10: TLabel;
    swchDownloadLOCALAUDIO: TSwitch;
    lblDownloadLOCALAUDIO: TLabel;
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
  errorsUrlsNums: TArray<Integer>;

implementation

{$R *.fmx}

{ Helper: экранирование поля для CSV }
function EscapeCSV(const Value: string): string;
begin
  if (Pos(CSV_DELIMITER, Value) > 0) or (Pos('"', Value) > 0) or
     (Pos(#13, Value) > 0) or (Pos(#10, Value) > 0) then
    Result := '"' + StringReplace(Value, '"', '""', [rfReplaceAll]) + '"'
  else
    Result := Value;
end;

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
  settings.audioBitrateIndex := comboBoxAudioBitrate.ItemIndex;
  settings.downloadPlaylist := swchPlaylist.IsChecked;
  settings.downloadMP3 := swchOnlyAudio.IsChecked;
  settings.downloadLOCALAUDIO := swchDownloadLOCALAUDIO.IsChecked;
  settings.createPlaylistDirs := swchAutoPlstFolders.IsChecked;
  settings.logsAutoScroll := swchLogsAutoScroll.IsChecked;
  writeConfigFile();
end;

procedure TfrmMain.updateFormFromSettings();
begin
  swchBigUI.IsChecked := settings.bigUi;
  edtDownloadDir.Text := settings.downloadDir;
  comboBoxResolution.ItemIndex := settings.videoResolutionIndex;
  comboBoxAudioBitrate.ItemIndex := settings.audioBitrateIndex;
  swchPlaylist.IsChecked := settings.downloadPlaylist;
  swchOnlyAudio.IsChecked := settings.downloadMP3;
  swchDownloadLOCALAUDIO.IsChecked := settings.downloadLOCALAUDIO;
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
    FInstanceMutexHandle := CreateMutex(nil, False, PChar(mutexName));
    if FInstanceMutexHandle = 0 then
      RaiseLastOSError;

    if GetLastError = ERROR_ALREADY_EXISTS then
    begin
      CloseHandle(FInstanceMutexHandle);
      FInstanceMutexHandle := 0;
      Continue;
    end
    else
    begin
      FInstanceNumber := instancesI;
      Break;
    end;
  end;

  if FInstanceNumber = 0 then
  begin
    ShowMessage('Достигнуто максимальное количество запущенных экземпляров (' +
      IntToStr(MAX_INSTANCES) + ').');
    Application.Terminate;
    Exit;
  end;

  TStyleManager.SetStyle(MaterialOxfordBlueSB.Style);

  lblInstanceNumber.Text := '#' + IntToStr(FInstanceNumber);
  frmMain.Caption := APP_NAME + ' - Инстанция #' + IntToStr(FInstanceNumber);
  lblTitle.Text := APP_LBL_TITLE;
  lblSwchBigUI.Text := 'UI x' + BIG_UI_MUL.ToString();
  lblDownloadLOCALAUDIO.Text := 'Локаль: ' + DEFAULT_LOCALE;

  log('[INFO] Запуск. Инстанция #' + IntToStr(FInstanceNumber));
  flushLogs();

  settings := defaultSettings;
  settings.downloadDir := TShellKnownPath.GetFolderPath(FOLDERID_Downloads);

  if not DirectoryExists(FILE_DIR) then
    CreateDir(FILE_DIR);

  // --- СОЗДАНИЕ CSV-ФАЙЛА ИСТОРИИ С ЗАГОЛОВКАМИ (если отсутствует) ---
  if not FileExists(FILE_HISTORY) then
  begin
    TFile.WriteAllText(FILE_HISTORY,
      'Date' + CSV_DELIMITER +
      'DownloadDir' + CSV_DELIMITER +
      'Resolution' + CSV_DELIMITER +
      'AudioBitrate' + CSV_DELIMITER +
      'Playlist' + CSV_DELIMITER +
      'MP3' + CSV_DELIMITER +
      'Localised' + CSV_DELIMITER +
      'PlaylistDirs' + CSV_DELIMITER +
      'Urls' + sLineBreak);
  end;

  for i := Low(videoResolutions) to High(videoResolutions) do
    comboBoxResolution.Items.Add(videoResolutions[i].ToString());

  for i := Low(audioBitrates) to High(audioBitrates) do
    comboBoxAudioBitrate.Items.Add(audioBitrates[i].ToString());

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

    indicator2.Visible := True;
    lblErrorsUrls.Text := Length(errorsUrlsNums).ToString() + ' из ' + Length(normalizedUrls).ToString();
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
  currentErrorURLNumber: Integer;
  R: TRegEx;
begin
  log('[INFO] СКАЧИВАНИЕ ЗАВЕРШЕНО');

  if Length(downloadErrors) > 0 then
  begin
    log('[ERROR] ВО ВРЕМЯ СКАЧИВАНИЯ ПРОИЗОШЛИ ОШИБКИ:');

    R := TRegEx.Create(ERROR_URL_NUMBER_REGEX);

    for i := Low(downloadErrors) to High(downloadErrors) do
    begin
      log(downloadErrors[i]);

      if not R.IsMatch(downloadErrors[i]) then
        Continue;

      currentErrorURLNumber := R.Match(downloadErrors[i]).Groups.Item[1].Value.ToInteger();
      if not TArray.Contains(errorsUrlsNums, currentErrorURLNumber) then
      begin
        SetLength(errorsUrlsNums, Length(errorsUrlsNums) + 1);
        errorsUrlsNums[High(errorsUrlsNums)] := currentErrorURLNumber;
      end;

    end;

    log('[ERROR] АХТУНГ!!! Скачивание завершено с ошибками у ' + Length(errorsUrlsNums).ToString() + ' из ' + Length(normalizedUrls).ToString() + ' адресов');
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
  currentUrlLaunchString := currentUrlLaunchString + ' --js-runtimes deno:' + FILE_DENO;
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
  if settings.downloadLOCALAUDIO then
    currentUrlLaunchString := currentUrlLaunchString + ' --extractor-args "youtube:player-client=android,tv_downgraded" -f "bestvideo+bestaudio[language='+DEFAULT_LOCALE+']/bestvideo+bestaudio" ';
  if settings.downloadMP3 then
  begin
    currentUrlLaunchString := currentUrlLaunchString + ' -f "bestaudio';
    if settings.downloadLOCALAUDIO then
      currentUrlLaunchString := currentUrlLaunchString + '[language^='+DEFAULT_LOCALE+']';
    currentUrlLaunchString := currentUrlLaunchString + '/bestaudio" -x --audio-format mp3 --audio-quality ' + audioBitrates[settings.audioBitrateIndex].ToString() + '';
  end;
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
  errorsUrlsNums := [];
  indicator2.Visible := False;
  updateIndicator();
  currentUrlProcessingIndex := 0;
end;

procedure TfrmMain.btnClearUrlsClick(Sender: TObject);
begin
  memoUrls.Lines.Clear();
end;

procedure TfrmMain.btnDownloadClick(Sender: TObject);
var
  csvLine: string;
  urlsConcat: string;
begin
  log(Format('[INFO] СТАРТ ЗАГРУЗКИ %s', [Date.Now().ToISO8601(False)]));

  updateSettingsFromForm();

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

  if not TFile.Exists(FILE_DENO) then
  begin
    log('[ERR] Не найден deno.exe! Откройте меню настройки или вручную скачайте в '
      + FILE_DENO);
    ShowMessage('Не найден DENO. Откройте меню настройки для скачивания, или скачайте вручную в '+ FILE_DENO + '. Без DENO трудно добиться стабильного скачивания из-за JS-задач от Youtube, решением которых DENO и занимается. После закрытия этого окна скачивание продолжится, но всё же, советую скачать DENO.');
  end;

  btnDownload.Enabled := False;
  canceling := False;
  resetDownload();
  indicator.Visible := False;

  normalizedUrls := GetNormalizedURLs(memoUrls.Text);

  // --- ЗАПИСЬ ИСТОРИИ В CSV (вместо старого текстового формата) ---
  urlsConcat := String.Join('|', normalizedUrls);
  csvLine :=
    EscapeCSV(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now)) + CSV_DELIMITER +
    EscapeCSV(settings.downloadDir) + CSV_DELIMITER +
    EscapeCSV(videoResolutions[settings.videoResolutionIndex].ToString()) + CSV_DELIMITER +
    EscapeCSV(audioBitrates[settings.audioBitrateIndex].ToString()) + CSV_DELIMITER +
    EscapeCSV(BoolToStr(settings.downloadPlaylist, True)) + CSV_DELIMITER +
    EscapeCSV(BoolToStr(settings.downloadMP3, True)) + CSV_DELIMITER +
    EscapeCSV(BoolToStr(settings.downloadLOCALAUDIO, True)) + CSV_DELIMITER +
    EscapeCSV(BoolToStr(settings.createPlaylistDirs, True)) + CSV_DELIMITER +
    EscapeCSV(urlsConcat);

  TFile.AppendAllText(FILE_HISTORY, csvLine + sLineBreak);

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
    downloadErrors[High(downloadErrors)] := '#URL::' + (currentUrlProcessingIndex + 1).ToString() + '::' + ANewLine;
  end;
end;

procedure TfrmMain.dscmndYTDLTerminated(Sender: TObject);
begin
  downloadInstanceFinished();
end;

end.
