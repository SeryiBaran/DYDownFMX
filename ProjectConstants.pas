unit ProjectConstants;

interface

const
  APP_VER = '1.3.9';
  APP_NAME = 'DYDownFMX';
  APP_LBL_TITLE = 'Качалка ' + APP_VER;
  TEMPLATE_PROGRESS =
    '[yt-dlp] | %(progress.downloaded_bytes)s | %(progress.total_bytes)s | %(progress.speed)s | %(progress.eta)s | %(progress._eta_str)s';
  FILE_DIR = '.\DYDownFiles';
  FILE_HISTORY = FILE_DIR + '\history__'+APP_VER+'.csv';
  CSV_DELIMITER = ';';
  FILE_LOGS_DIR = FILE_DIR + '\logs';
  FILE_CONFIG = FILE_DIR + '\config.ini';
  FILE_YTDLP = FILE_DIR + '\yt-dlp.exe';
  FFMPEG_DIR = FILE_DIR + '\ffmpeg';
  FILE_FFMPEG_DIR = FFMPEG_DIR + '\bin';
  FILE_FFMPEG_DOWNLOADED_INDIR = 'ffmpeg-master-latest-win64-gpl-shared';
  FILE_FFMPEG_DOWNLOADED = FILE_DIR + '\' +
    FILE_FFMPEG_DOWNLOADED_INDIR + '.zip';
  FILE_DENO_EXENAME = 'deno.exe';
  FILE_DENO = FILE_DIR + '\' + FILE_DENO_EXENAME;
  FILE_DENO_DOWNLOADED = FILE_DIR + '\' + 'deno-x86_64-pc-windows-msvc.zip';
  LATEST_YTDLP_DOWNLOAD_URL =
    'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe';
  LATEST_FFMPEG_DOWNLOAD_URL =
    'https://github.com/yt-dlp/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl-shared.zip';
  LATEST_DENO_DOWNLOAD_URL =
    'https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip';
  BIG_UI_MUL = 1.25;
  MAX_INSTANCES = 128;
  BASE_MUTEX_NAME = 'DYDownFMX_' + APP_VER + '__Instance_';
  videoResolutions: TArray<Integer> = [144, 240, 360, 480, 720, 1080,
    1440, 2160];
  audioBitrates: TArray<Integer> = [128, 192, 320];
  ERROR_URL_NUMBER_REGEX: string = '^#URL::(\d+)::';
  DEFAULT_LOCALE = 'ru';
  DEFAULT_COOKIES_FILE = FILE_DIR + '\cookies.txt';

implementation

end.
