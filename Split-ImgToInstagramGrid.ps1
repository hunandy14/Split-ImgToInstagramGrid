# 載入 System.Drawing 組件
Add-Type -AssemblyName System.Drawing

# 將圖片切成IG九宮格
function Split-ImgToInstagramGrid {
    [Alias("sIGgrid")]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,
        
        [Alias("o")]
        [string]$Output,
        
        [Alias("b")]
        [int[]]$BgColor = @(255, 255, 255),

        [Alias("l")]
        [ValidateSet("square", "rectangle")]
        [string]$Layout  = "square"
    )
    
    # 偏移量 (防止計算誤差出現白邊)
    $CUT_OFFSET = 4
    
    # 選擇格式參數
    switch ($Layout ) {
        "square" {
            $CUT_RADIO_WIDTH = 810 + $CUT_OFFSET
            $CUT_RADIO_HEIGHT = 1080
            $OUTPUT_RATIO_WIDTH = 1
            $OUTPUT_RATIO_HEIGHT = 1
        }
        "rectangle" {
            $CUT_RADIO_WIDTH = 1012.5 + $CUT_OFFSET
            $CUT_RADIO_HEIGHT = 1350
            $OUTPUT_RATIO_WIDTH = 4
            $OUTPUT_RATIO_HEIGHT = 5
        }
    }
    
    # 建立輸出目錄
    if (-not $Output) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $Output = Join-Path $env:TEMP "output_$timestamp"
    }
    
    # 將路徑轉換為絕對路徑
    $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $Output = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Output)
    
    # 建立輸出目錄
    New-Item -ItemType Directory -Force -Path $Output | Out-Null
    
    # 檢查輸入檔案是否存在
    if (-not (Test-Path $Path)) { throw "Input file does not exist: $Path" }

    try {
        # 讀取圖片
        $img = [System.Drawing.Image]::FromFile($Path)
        
        # 計算目標尺寸
        $targetW = $img.Width
        $targetH = [Math]::Ceiling($targetW * $CUT_RADIO_HEIGHT / $CUT_RADIO_WIDTH)
        
        # 確保是3的倍數
        $targetW = $targetW - ($targetW % 3)
        $targetH = $targetH - ($targetH % 3)
        
        # 如果原始高度已經超過目標高度，則交換寬高
        if ($img.Height -gt $targetH) { $targetW, $targetH = $targetH, $targetW }
        
        # 建立新的圖片並補白
        $newImg = New-Object System.Drawing.Bitmap($targetW, $targetH)
        $graphics = [System.Drawing.Graphics]::FromImage($newImg)
        $graphics.Clear([System.Drawing.Color]::FromArgb($BgColor[0], $BgColor[1], $BgColor[2]))
        
        # 計算補白位置
        $padW = ($targetW - $img.Width) / 2
        $padH = ($targetH - $img.Height) / 2
        
        # 繪製原始圖片
        $graphics.DrawImage($img, $padW, $padH, $img.Width, $img.Height)
        
        # 切成九宮格
        $gridW = $targetW / 3
        $gridH = $targetH / 3
        
        for ($row = 2; $row -ge 0; $row--) {
            for ($col = 2; $col -ge 0; $col--) {
                $left = $col * $gridW
                $upper = $row * $gridH
                
                # 取長邊為基準
                if ($gridW -gt $gridH) {
                    # 如果寬度較長，以寬度為基準
                    [int]$finalW = $gridW
                    [int]$finalH = [Math]::Ceiling($finalW * $OUTPUT_RATIO_HEIGHT / $OUTPUT_RATIO_WIDTH)
                } else {
                    # 如果高度較長，以高度為基準
                    [int]$finalH = $gridH
                    [int]$finalW = [Math]::Ceiling($finalH * $OUTPUT_RATIO_WIDTH / $OUTPUT_RATIO_HEIGHT)
                }
                
                # 確保寬高與原始尺寸的奇偶性一致
                if ($gridW % 2) {
                    if (-not ($finalW % 2)) { $finalW++ }
                } else {
                    if ($finalW % 2) { $finalW++ }
                }
                if ($gridH % 2) {
                    if (-not ($finalH % 2)) { $finalH++ }
                } else {
                    if ($finalH % 2) { $finalH++ }
                }
                
                # 建立新的畫布
                $tile = New-Object System.Drawing.Bitmap($finalW, $finalH)
                $tileGraphics = [System.Drawing.Graphics]::FromImage($tile)
                $tileGraphics.Clear([System.Drawing.Color]::FromArgb($BgColor[0], $BgColor[1], $BgColor[2]))
                
                # 計算置中位置
                $padW = [Math]::Max(0, [Math]::Floor(($finalW - $gridW) / 2))
                $padH = [Math]::Max(0, [Math]::Floor(($finalH - $gridH) / 2))
                
                # 複製到新畫布
                $tileGraphics.DrawImage($newImg, 
                    [System.Drawing.Rectangle]::new($padW, $padH, $gridW, $gridH),
                    [System.Drawing.Rectangle]::new($left, $upper, $gridW, $gridH),
                    [System.Drawing.GraphicsUnit]::Pixel)
                
                # 儲存九宮格圖片
                $tileNum = (2 - $row) * 3 + (2 - $col) + 1
                $tilePath = Join-Path $Output "grid_$tileNum.jpg"
                $tile.Save($tilePath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                
                # 釋放資源
                $tileGraphics.Dispose()
                $tile.Dispose()
            }
        }
        
        # 釋放資源
        $graphics.Dispose()
        $newImg.Dispose()
        $img.Dispose()
        
        Write-Host "Processing completed! Output directory: $Output"
    }
    catch {
        throw
    }
} #
# Split-ImgToInstagramGrid -Path "Image.jpg" -Output "output" -Layout "rectangle"
# Split-ImgToInstagramGrid -Path "Image.jpg" -Output "output"
# Split-ImgToInstagramGrid -Path "Image.jpg"
