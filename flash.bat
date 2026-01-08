@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================
:: ESP32 燒錄工具 v4.6
:: 使用 esptool 直接燒錄
:: 建立時間: 2026-01-08 16:30:00
:: Powered by Yuanpro@Nuxtack
:: 
:: 用法: flash_esp32.bat [MCU型號] [COM編號] [上傳模式]
:: ============================================

:: 檢查是否要顯示說明
if "%~1"=="?" goto :show_help
if "%~1"=="/?" goto :show_help
if "%~1"=="-?" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
if "%~1"=="/h" goto :show_help
if "%~1"=="/help" goto :show_help

:: 預設值
set "DEFAULT_MCU=esp32s3"
set "DEFAULT_PORT=3"
set "DEFAULT_MODE=cdc"
set "BAUD_RATE=921600"

:: 取得參數
set "MCU=%~1"
set "PORT_NUM=%~2"
set "UPLOAD_MODE=%~3"

:: 如果沒有參數，使用預設值
if "%MCU%"=="" set "MCU=%DEFAULT_MCU%"
if "%PORT_NUM%"=="" set "PORT_NUM=%DEFAULT_PORT%"
if "%UPLOAD_MODE%"=="" set "UPLOAD_MODE=%DEFAULT_MODE%"

:: 驗證 MCU 型號
set "VALID_MCU=0"
for %%m in (esp32 esp32s2 esp32s3 esp32c2 esp32c3 esp32c5 esp32c6 esp32h2 esp32p4) do (
    if /i "%MCU%"=="%%m" set "VALID_MCU=1"
)
if "!VALID_MCU!"=="0" (
    echo.
    echo [錯誤] 無效的 MCU 型號: %MCU%
    echo.
    goto :show_help
)

:: 驗證 COM 埠編號 (必須是數字)
set "PORT_VALID=1"
for /f "delims=0123456789" %%i in ("%PORT_NUM%") do set "PORT_VALID=0"
if "%PORT_NUM%"=="" set "PORT_VALID=0"
if "!PORT_VALID!"=="0" (
    echo.
    echo [錯誤] 無效的 COM 埠編號: %PORT_NUM%
    echo        COM 埠編號必須是數字
    echo.
    goto :show_help
)

:: 驗證上傳模式
set "VALID_MODE=0"
for %%m in (uart cdc hwcdc tinyusb otg) do (
    if /i "%UPLOAD_MODE%"=="%%m" set "VALID_MODE=1"
)
if "!VALID_MODE!"=="0" (
    echo.
    echo [錯誤] 無效的上傳模式: %UPLOAD_MODE%
    echo.
    goto :show_help
)

:: 組合 COM 埠名稱
set "PORT=COM%PORT_NUM%"

:: 顯示標題
echo.
echo ╔════════════════════════════════════════════════════╗
echo ║       ESP32 燒錄工具 v4.6                          ║
echo ║       Build: 2026-01-08 16:30:00                   ║
echo ║       Powered by Yuanpro@Nuxtack                   ║
echo ╚════════════════════════════════════════════════════╝
echo.

:: ========================================
:: 尋找 esptool
:: ========================================
set "ESPTOOL="
set "ARDUINO15=%USERPROFILE%\AppData\Local\Arduino15"

for /d %%v in ("%ARDUINO15%\packages\esp32\tools\esptool_py\*") do (
    if exist "%%v\esptool.exe" set "ESPTOOL=%%v\esptool.exe"
)

if "!ESPTOOL!"=="" (
    echo [錯誤] 找不到 esptool.exe
    echo 請確認已在 Arduino IDE 安裝 ESP32 開發板套件
    goto :error
)

echo [找到 esptool]
echo   !ESPTOOL!
echo.

:: 根據上傳模式設定 reset 參數 (使用 esptool v5.x 新語法)
set "MODE_DESC=UART0 (傳統串列埠)"
set "BEFORE_RESET=default-reset"
set "AFTER_RESET=hard-reset"

if /i "%UPLOAD_MODE%"=="cdc" (
    set "MODE_DESC=USB CDC (Hardware CDC)"
    set "BEFORE_RESET=usb-reset"
)
if /i "%UPLOAD_MODE%"=="hwcdc" (
    set "MODE_DESC=USB CDC (Hardware CDC)"
    set "BEFORE_RESET=usb-reset"
    set "UPLOAD_MODE=cdc"
)
if /i "%UPLOAD_MODE%"=="tinyusb" (
    set "MODE_DESC=USB-OTG CDC (TinyUSB)"
    set "BEFORE_RESET=usb-reset"
)
if /i "%UPLOAD_MODE%"=="otg" (
    set "MODE_DESC=USB-OTG CDC (TinyUSB)"
    set "BEFORE_RESET=usb-reset"
    set "UPLOAD_MODE=tinyusb"
)

:: 顯示設定
echo [設定資訊]
echo   MCU 型號  : %MCU%
echo   串列埠    : %PORT%
echo   上傳模式  : !MODE_DESC!
echo   目前目錄  : %CD%
echo.

:: 建立預期的 build 目錄路徑
set "BUILD_DIR=build\esp32.esp32.%MCU%"

:: ========================================
:: 步驟 1: 搜尋編譯檔案
:: ========================================
echo [步驟 1/3] 搜尋編譯檔案...
set "BIN_FILE="
set "BIN_TYPE="

:: 方法1: 搜尋 build 目錄中的 merged.bin
if exist "%BUILD_DIR%\*.ino.merged.bin" (
    echo   搜尋目錄: %BUILD_DIR%
    for %%f in ("%BUILD_DIR%\*.ino.merged.bin") do (
        set "BIN_FILE=%%f"
        set "BIN_TYPE=merged"
        echo   找到合併檔: %%~nxf
    )
    goto :found_file
)

:: 方法2: 搜尋 build 目錄中的 .ino.bin
if exist "%BUILD_DIR%\*.ino.bin" (
    echo   搜尋目錄: %BUILD_DIR%
    for %%f in ("%BUILD_DIR%\*.ino.bin") do (
        set "BIN_FILE=%%f"
        set "BIN_TYPE=app"
        echo   找到主程式: %%~nxf
    )
    goto :found_file
)

:: 方法3: 搜尋目前目錄的 merged.bin
echo   在目前目錄搜尋...
for %%f in (*.ino.merged.bin) do (
    set "BIN_FILE=%%f"
    set "BIN_TYPE=merged"
    echo   找到: %%f
    goto :found_file
)

:: 方法4: 搜尋目前目錄的 .ino.bin
for %%f in (*.ino.bin) do (
    set "BIN_FILE=%%f"
    set "BIN_TYPE=app"
    echo   找到: %%f
    goto :found_file
)

:: 方法5: 搜尋任何 .bin
for %%f in (*.bin) do (
    set "BIN_FILE=%%f"
    set "BIN_TYPE=app"
    echo   找到: %%f
    goto :found_file
)

:: 沒找到任何檔案
echo.
echo [錯誤] 找不到 .bin 檔案
echo.
if exist "build" (
    echo 發現以下 build 目錄：
    for /d %%d in (build\*) do echo   %%d
    echo.
    echo 請確認 MCU 型號參數是否正確 (目前: %MCU%)
) else (
    echo 請先在 Arduino IDE 執行：
    echo   Sketch → Export Compiled Binary
)
goto :error

:found_file
:: ========================================
:: 步驟 2: 確認燒錄
:: ========================================
echo.
echo [步驟 2/3] 準備燒錄...
echo   檔案路徑: !BIN_FILE!
echo   檔案類型: !BIN_TYPE!
echo   連接埠  : %PORT%
echo   上傳模式: !MODE_DESC!

:: 顯示檔案大小
for %%A in ("!BIN_FILE!") do (
    set /a "SIZE_KB=%%~zA / 1024"
    echo   檔案大小: !SIZE_KB! KB
)

:: 設定燒錄地址
if "!BIN_TYPE!"=="merged" (
    echo.
    echo   [說明] 使用合併檔從 0x0 地址燒錄
    echo          包含 bootloader + 分區表 + 主程式
    set "FLASH_ADDR=0x0"
) else (
    echo.
    echo   [說明] 僅燒錄主程式到 0x10000 地址
    set "FLASH_ADDR=0x10000"
)

echo.
<nul set /p "=確定要燒錄嗎？[Y/n]: Y"
<nul set /p "="
set "CONFIRM=Y"
set /p "CONFIRM="
if /i "!CONFIRM!"=="n" (
    echo.
    echo 已取消燒錄
    goto :end
)
echo.

:: ========================================
:: 步驟 3: 執行燒錄
:: ========================================
echo.
echo [步驟 3/3] 開始燒錄...
echo ════════════════════════════════════════════
echo.

echo 執行命令：
echo "!ESPTOOL!" --chip %MCU% --port %PORT% --baud %BAUD_RATE% --before !BEFORE_RESET! --after !AFTER_RESET! write-flash -z --flash-mode dio --flash-freq 80m --flash-size detect !FLASH_ADDR! "!BIN_FILE!"
echo.

"!ESPTOOL!" --chip %MCU% --port %PORT% --baud %BAUD_RATE% --before !BEFORE_RESET! --after !AFTER_RESET! write-flash -z --flash-mode dio --flash-freq 80m --flash-size detect !FLASH_ADDR! "!BIN_FILE!"

:: ========================================
:: 檢查結果
:: ========================================
echo.
echo ════════════════════════════════════════════
if errorlevel 1 (
    echo [失敗] 燒錄過程發生錯誤
    echo.
    echo 常見問題排除：
    echo   1. 讓 ESP32 進入下載模式：
    echo      按住 BOOT → 按一下 RST → 放開 BOOT
    echo.
    echo   2. 確認 %PORT% 正確
    echo.
    echo   3. 嘗試降低傳輸速率：
    echo      修改批次檔中 BAUD_RATE=460800 或 115200
    goto :error
) else (
    echo [成功] 燒錄完成！
    echo.
    echo 提示：如果 ESP32 沒有自動重啟，請按一下 RST 按鈕
)

goto :end

:: ========================================
:: 顯示說明
:: ========================================
:show_help
echo.
echo ╔════════════════════════════════════════════════════╗
echo ║       ESP32 燒錄工具 v4.6                          ║
echo ║       Build: 2026-01-08 16:30:00                   ║
echo ║       Powered by Yuanpro@Nuxtack                   ║
echo ╚════════════════════════════════════════════════════╝
echo.
echo 用法: flash_esp32.bat [MCU型號] [COM編號] [上傳模式]
echo.
echo 參數說明:
echo.
echo   MCU型號      ESP32 晶片型號 (預設: %DEFAULT_MCU%)
echo                可用選項:
echo                  esp32    - ESP32 (原版，雙核 Xtensa LX6)
echo                  esp32s2  - ESP32-S2 (單核 Xtensa LX7，USB OTG)
echo                  esp32s3  - ESP32-S3 (雙核 Xtensa LX7，AI 加速)
echo                  esp32c2  - ESP32-C2 (單核 RISC-V，低成本)
echo                  esp32c3  - ESP32-C3 (單核 RISC-V，安全啟動)
echo                  esp32c5  - ESP32-C5 (單核 RISC-V，WiFi 6 雙頻)
echo                  esp32c6  - ESP32-C6 (單核 RISC-V，WiFi 6 + Zigbee)
echo                  esp32h2  - ESP32-H2 (單核 RISC-V，Zigbee/Thread)
echo                  esp32p4  - ESP32-P4 (雙核 RISC-V，高效能)
echo.
echo   COM編號      串列埠編號，只需輸入數字 (預設: %DEFAULT_PORT%)
echo                例如: 3 表示 COM3, 82 表示 COM82
echo.
echo   上傳模式     USB/UART 上傳模式 (預設: %DEFAULT_MODE%)
echo                可用選項:
echo                  uart    - UART0 (傳統串列埠，需 USB-UART 晶片)
echo                  cdc     - USB CDC (Hardware CDC，內建 USB)
echo                  hwcdc   - 同 cdc
echo                  tinyusb - USB-OTG CDC (TinyUSB)
echo                  otg     - 同 tinyusb
echo.
echo 範例:
echo.
echo   flash_esp32.bat                      使用全部預設值
echo   flash_esp32.bat esp32s3 82 cdc       ESP32-S3, COM82, USB CDC 模式
echo   flash_esp32.bat esp32s3 5            ESP32-S3, COM5, 預設上傳模式
echo   flash_esp32.bat esp32c3 10 uart      ESP32-C3, COM10, UART 模式
echo   flash_esp32.bat esp32c6 7 cdc        ESP32-C6, COM7, USB CDC 模式
echo   flash_esp32.bat ?                    顯示此說明
echo.
echo 注意事項:
echo.
echo   1. 請先在 Arduino IDE 執行「匯出已編譯的二進位檔」
echo      Sketch → Export Compiled Binary
echo.
echo   2. 此批次檔會自動搜尋專案目錄下的:
echo      build\esp32.esp32.[MCU型號]\*.ino.merged.bin
echo.
echo   3. 上傳模式必須與 Arduino IDE 編譯時的設定一致
echo.
echo   4. 如果燒錄失敗，請嘗試手動進入下載模式:
echo      按住 BOOT → 按一下 RST → 放開 BOOT
echo.
goto :end

:error
echo.
pause
exit /b 1

:end
echo.
pause
exit /b 0
