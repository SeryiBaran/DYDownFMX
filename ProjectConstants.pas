unit ProjectConstants;

interface

uses ConfigUnit;

const
  APP_VER = '1.3.2';
  APP_NAME = 'DYDownFMX';
  APP_LBL_TITLE = 'Качалка ' + APP_VER;
  TEMPLATE_PROGRESS =
    '[yt-dlp] | %(progress.downloaded_bytes)s | %(progress.total_bytes)s | %(progress.speed)s | %(progress.eta)s | %(progress._eta_str)s';
  FILE_DIR = '.\DYDownFiles';
  FILE_HISTORY = FILE_DIR + '\history.txt';
  FILE_LOGS_DIR = FILE_DIR + '\logs';
  FILE_CONFIG = FILE_DIR + '\config.json';
  FILE_YTDLP = FILE_DIR + '\yt-dlp.exe';
  FILE_FFMPEG_DIR = FILE_DIR + '\ffmpeg';
  FILE_FFMPEG = FILE_FFMPEG_DIR + '\ffmpeg.exe';
  FILE_FFMPEG_DOWNLOADED_INDIR = 'ffmpeg-master-latest-win64-gpl';
  FILE_FFMPEG_DOWNLOADED = FILE_DIR + '\' +
    FILE_FFMPEG_DOWNLOADED_INDIR + '.zip';
  LATEST_YTDLP_DOWNLOAD_URL =
    'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe';
  LATEST_FFMPEG_DOWNLOAD_URL =
    'https://github.com/yt-dlp/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip';
  BIG_UI_MUL = 1.25;
  MAX_INSTANCES = 256;
  BASE_MUTEX_NAME = 'DYDownFMX_' + APP_VER + '__Instance_';
  videoResolutions: TArray<Integer> = [144, 240, 360, 480, 720, 1080,
    1440, 2160];
  defaultSettings: TSettings = (bigUi: True; downloadDir: FILE_DIR;
    videoResolutionIndex: 2; downloadPlaylist: False; downloadMP3: False;
    createPlaylistDirs: False; logsAutoScroll: True;);

implementation

end.
