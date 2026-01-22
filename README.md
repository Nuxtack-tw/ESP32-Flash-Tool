# ESP32 Flash Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows-blue.svg)](https://www.microsoft.com/windows)
[![ESP32](https://img.shields.io/badge/ESP32-Supported-green.svg)](https://www.espressif.com/)

一個簡單易用的 ESP32 燒錄工具，支援 Arduino IDE 2.x 匯出的二進位檔案。

## ✨ 功能特點

- 🔍 **自動搜尋** - 自動搜尋 Arduino IDE 2.x 的 `build` 目錄結構
- 🎯 **智慧選擇** - 優先使用 `merged.bin` 完整燒錄（含 bootloader + 分區表）
- 🔌 **多種上傳模式** - 支援 UART、USB CDC、TinyUSB 等上傳模式
- 📦 **全系列支援** - 支援所有 ESP32 晶片型號（ESP32/S2/S3/C2/C3/C5/C6/H2/P4）
- ⚡ **一鍵燒錄** - 預設確認選項，直接按 Enter 即可開始燒錄
- 🛡️ **參數驗證** - 自動驗證參數正確性，錯誤時顯示詳細說明

## 📋 系統需求

- Windows 10 / 11
- [Arduino IDE 2.x](https://www.arduino.cc/en/software) 已安裝 ESP32 開發板套件
- ESP32 Soc
- [Arduino core for the ESP32 family  V3.x.x](https://github.com/espressif/arduino-esp32)

## 🚀 快速開始

### 安裝

1. 下載 `flash.bat` 到你的 Arduino 專案目錄
2. 確認已在 Arduino IDE 安裝 ESP32 開發板套件

### 使用方式

1. 在 Arduino IDE 中編譯並匯出二進位檔：
   - **Sketch → Export Compiled Binary**（草稿碼 → 匯出已編譯的二進位檔）

2. 開啟命令提示字元，進入專案目錄：
   ```batch
   cd C:\Users\你的名稱\Documents\Arduino\你的專案
   ```

3. 執行燒錄：
   ```batch
   flash.bat esp32s3 5 cdc
   ```

## 📖 使用說明

### 語法

```
flash.bat [MCU型號] [COM編號] [上傳模式]
```

### 參數說明

| 參數 | 說明 | 預設值 |
|------|------|--------|
| MCU型號 | ESP32 晶片型號 | `esp32s3` |
| COM編號 | 串列埠編號（只需數字） | `3` |
| 上傳模式 | USB/UART 上傳模式 | `cdc` |

### 支援的 MCU 型號

| 型號 | 說明 |
|------|------|
| `esp32` | ESP32 原版（雙核 Xtensa LX6） |
| `esp32s2` | ESP32-S2（單核 Xtensa LX7，USB OTG） |
| `esp32s3` | ESP32-S3（雙核 Xtensa LX7，AI 加速） |
| `esp32c2` | ESP32-C2（單核 RISC-V，低成本） |
| `esp32c3` | ESP32-C3（單核 RISC-V，安全啟動） |
| `esp32c5` | ESP32-C5（單核 RISC-V，WiFi 6 雙頻） |
| `esp32c6` | ESP32-C6（單核 RISC-V，WiFi 6 + Zigbee） |
| `esp32h2` | ESP32-H2（單核 RISC-V，Zigbee/Thread） |
| `esp32p4` | ESP32-P4（雙核 RISC-V，高效能） |

### 支援的上傳模式

| 模式 | 說明 |
|------|------|
| `uart` | UART0 傳統串列埠（需 USB-UART 晶片） |
| `cdc` / `hwcdc` | USB CDC（Hardware CDC，內建 USB） |
| `tinyusb` / `otg` | USB-OTG CDC（TinyUSB） |

## 💡 使用範例

```batch
# 使用全部預設值（ESP32-S3, COM3, CDC 模式）
flash.bat

# ESP32-S3, COM82, USB CDC 模式
flash.bat esp32s3 82 cdc

# ESP32-S3, COM5, 預設上傳模式
flash.bat esp32s3 5

# ESP32-C3, COM10, UART 模式
flash.bat esp32c3 10 uart

# ESP32-C6, COM7, USB CDC 模式
flash.bat esp32c6 7 cdc

# 顯示說明
flash.bat ?
```

## 📁 目錄結構

批次檔會自動搜尋以下位置的 `.bin` 檔案：

```
你的專案/
├── 專案名稱.ino
├── flash.bat              ← 放這裡
└── build/
    └── esp32.esp32.{MCU型號}/
        ├── 專案名稱.ino.bin
        ├── 專案名稱.ino.bootloader.bin
        ├── 專案名稱.ino.partitions.bin
        └── 專案名稱.ino.merged.bin  ← 優先使用
```

## ⚠️ 常見問題

### 燒錄失敗

1. **手動進入下載模式**：按住 `BOOT` → 按一下 `RST` → 放開 `BOOT`
2. **確認 COM 埠正確**：執行 `arduino-cli board list` 查看
3. **降低傳輸速率**：修改批次檔中 `BAUD_RATE=460800` 或 `115200`

### 找不到 .bin 檔案

1. 確認已在 Arduino IDE 執行「匯出已編譯的二進位檔」
2. 確認 MCU 型號參數與編譯時選擇的開發板一致

### 上傳模式不符

上傳模式必須與 Arduino IDE 編譯時的設定一致：
- **Tools → USB CDC On Boot** 的設定
- **Tools → Upload Mode** 的設定

## 🔧 自訂預設值

編輯 `flash.bat` 開頭的預設值設定：

```batch
:: 預設值
set "DEFAULT_MCU=esp32s3"
set "DEFAULT_PORT=3"
set "DEFAULT_MODE=cdc"
set "BAUD_RATE=921600"
```

## 📄 授權條款

本專案採用 [MIT License](LICENSE) 授權。

## 🙏 致謝

- [Espressif Systems](https://www.espressif.com/) - ESP32 晶片製造商
- [Arduino](https://www.arduino.cc/) - Arduino IDE
- [esptool](https://github.com/espressif/esptool) - ESP32 燒錄工具

---

**Powered by Yuanpro@Nuxtack**
