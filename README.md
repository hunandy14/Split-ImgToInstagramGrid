# IG 九宮格切圖工具

這是一個可以將任意尺寸的圖片自動切成 Instagram 九宮格的工具。工具會自動將圖片補白成 4:5 比例（1080x1350），然後切成 3x3 的九宮格。

## 安裝需求

```bash
pip install -r requirements.txt
```

## 使用方法

基本用法：
```bash
python ig_grid.py 你的圖片.jpg
```

指定輸出目錄：
```bash
python ig_grid.py 你的圖片.jpg --output 輸出目錄
```

指定背景顏色（RGB）：
```bash
python ig_grid.py 你的圖片.jpg --bg-color 255 255 255
```

## 輸出檔案

程式會在輸出目錄中產生以下檔案：
- `padded.jpg`：補白後的完整圖片
- `grid_1.jpg` 到 `grid_9.jpg`：九宮格圖片
- `merged.jpg`：將九宮格合併回來的驗證圖片

## 注意事項

- 輸入圖片可以是任意尺寸，程式會自動調整並補白
- 預設背景顏色為白色 (255, 255, 255)
- 如果不指定輸出目錄，會自動建立一個帶時間戳的目錄 