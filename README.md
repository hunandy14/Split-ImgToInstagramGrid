# IG 九宮格切圖工具

這是一個可以將任意尺寸的圖片自動切成 Instagram 九宮格的 PowerShell 工具。工具會自動將圖片補白成指定比例，然後切成 3x3 的九宮格。

## 功能特點

- 支援正方形（1:1）和長方形（4:5）兩種輸出格式
- 自動計算最佳尺寸並補白
- 自動確保輸出尺寸為 3 的倍數
- 自動處理圖片方向（橫向/縱向）
- 支援自訂背景顏色

## 使用方法

基本用法：
```powershell
.\ig_grid.ps1 -Path "Image.jpg"
```

指定輸出目錄：
```powershell
.\ig_grid.ps1 -Path "Image.jpg" -Output "output"
```

指定背景顏色（RGB）：
```powershell
.\ig_grid.ps1 -Path "Image.jpg" -BgColor 255, 255, 255
```

指定輸出格式：
```powershell
# 正方形格式（1:1）
.\ig_grid.ps1 -Path "Image.jpg" -Layout "square"

# 長方形格式（4:5）
.\ig_grid.ps1 -Path "Image.jpg" -Layout "rectangle"
```

參數說明：
- `-Path`：輸入圖片路徑（必要）
- `-Output`：輸出目錄（選用，預設為 output_時間戳）
- `-BgColor`：背景顏色，RGB 格式（選用，預設為白色 255, 255, 255）
- `-Layout`：輸出格式（選用，預設為 "square"）
  - `square`：正方形格式（1:1）
  - `rectangle`：長方形格式（4:5）

## 輸出檔案

程式會在輸出目錄中產生以下檔案：
- `grid_1.jpg` 到 `grid_9.jpg`：九宮格圖片，從左到右、從上到下編號

## 注意事項

- 輸入圖片可以是任意尺寸，程式會自動調整並補白
- 程式會自動確保輸出尺寸為 3 的倍數，以確保切割精確
- 如果原始圖片高度超過計算後的高度，程式會自動交換寬高
- 預設背景顏色為白色 (255, 255, 255)
- 如果不指定輸出目錄，會自動建立一個帶時間戳的目錄 