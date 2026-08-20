# DYDownFMX

![Логотип](./Logo.png)

![Скриншот](./screenshot.png)

Утилита-обёртка над YT-DLP. Создано на Delphi 13.0 FMX для Windows 10+.

Последняя версия - [скачать (11 896 KiB)](https://github.com/SeryiBaran/DYDownFMX/releases/latest/download/DYDownFMX.exe)

## Фичи

- **Управление зависимостями** - встроенные кнопки для автоматической загрузки (обновления):
  - `yt-dlp.exe` (сама качалка)
  - `ffmpeg.exe` (для конвертации. Рекомендуется)
  - `deno.exe` (для выполнения JS-скриптов, повышает стабильность. Рекомендуется)
  - TTS-голос (тихо, абсолютно без участия пользователя)s
- **Масштабирование интерфейса (BigUI)** - увеличение всех контролов основного окна до 125% для удобства работы на больших экранах или с проблемами зрения
- **Голосовой отчёт (TTS)** - по окончании загрузки программа **сообщит об этом вслух**, назовет свой номер и **скажет количество ошибок** (если есть). Работает это через SAPI голос `Aleksandr-hq`. Устанавливается одной кнопкой в настройках, без участия пользователя
- **Скачивание русской аудиодорожки**
- **Поддержка плейлистов** - загрузка всего плейлиста с автоматическим созданием папки под каждый плейлист (по желанию)
- **Обход ограничений через cookies** - выберите cookies.txt для доступа к возрастным или приватным видео
- **Работает на любой картошке** - Delphi. Этим всё сказано. Ну а для фанатов Jayfeather'а - ест 43MB озу и пару процентов ЦП.
- **Поддержка нескольких экземпляров** - по причине выше можно запустить до 32 инстанций программы одновременно (все они пронумерованы)
- **История загрузок** - все закачки сохраняются в CSV-файл со всеми параметрами
- **Сохранение настроек** - все хранится в INI-файле
- **Конвертация в MP3** сразу
- **Сохранение вывода в файл** - полезно иногда, не?
- **Проброс параметров до yt-dlp**
- **Индикатор ошибок** - красный кружок у кнопки скачивания покажет кол-во ошибок и посчитает проблемные адреса. Если все оки, он будет зелёным и покажет "0"
- **Рофлы** - Александр будет рофлить. По ситуации.

---

## Инфа

Перед использованием откройте `Настройки` и нажмите кнопки для скачивания зависимостей.

Если программа не работает или выдает ошибки, удалите папку `DYDownFiles` и перезапустите программу.

Настройки сохраняются в `DYDownFiles/config.ini`, а история загрузок в `DYDownFiles/history__x.x.x.csv`. В ранних версиях это были `DYDownFiles/config.json`, и `DYDownFiles/history.txt` соответственно.

Софтина кушает очень мало оперативки. При этом статично - что в фоне, что при работе жрет одинаково.

![Скриншот потреблению ОЗУ](./screenshot__ram.png)

А ещё экономит ЦП - сделан тротлинг 250мс для вывода логов.

## Если не работают кнопки для установки YT-DLP и FFMPEG

1. Скачайте `yt-dlp.exe` отсюда:  
  [https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe](https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe)  
  Либо чтобы 100% работало (но, возможно, постарее) - отсюда файл `yt-dlp.exe`:  
  [https://github.com/yt-dlp/yt-dlp/releases/tag/2026.03.03](https://github.com/yt-dlp/yt-dlp/releases/tag/2026.03.03)
2. Скачайте `ffmpeg-master-latest-win64-gpl.zip` отсюда:  
  [https://github.com/yt-dlp/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip](https://github.com/yt-dlp/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip)  
  Либо чтобы 100% работало (но постарее) - отсюда файл `ffmpeg-N-122609-g364d5dda91-win64-gpl.zip`:  
  [https://github.com/yt-dlp/FFmpeg-Builds/releases/tag/autobuild-2026-01-31-14-23](https://github.com/yt-dlp/FFmpeg-Builds/releases/tag/autobuild-2026-01-31-14-23)

Теперь скопируйте `yt-dlp.exe` в папку `DYDownFiles` рядом с программой (должна создаться после запуска программы), а из архива `ffmpeg-master-latest-win64-gpl.zip` вытащите папку `bin` и положите в `DYDownFiles/ffmpeg`.

Должно получиться такое древо:

```
- DYDownFiles
--- ffmpeg
--- --- bin
--- --- --- ffmpeg.exe
--- --- --- ffprobe.exe
--- --- --- ... и т.д. ...
--- yt-dlp.exe
```

## Для разрабов

Программа сделана на Delphi 13 со следующими библиотеками:

- [DosCommand](https://github.com/TurboPack/DOSCommand) (доступна в Delphi GetIt)

HTTP(s) клиент украден с StackOverFlow, с Indy не получается без багов (я знал Delphi на практике всего около недельки на момент 2025-07-01T21:44:29+03:00).

### TODO

- Сделать нормальное хранение настроек в коде. Заебало трехслойное сохранение
- Заюзать полезные фичи и код из моей нычки `E:\files\projects\delphi_projects` (мб progress bar, etc.)
- [https://docwiki.embarcadero.com/Libraries/Athens/en/System.Net.HttpClient.THTTPClient](https://docwiki.embarcadero.com/Libraries/Athens/en/System.Net.HttpClient.THTTPClient)
- Сделать README для юзаков в LaTeX
