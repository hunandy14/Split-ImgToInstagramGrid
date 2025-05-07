# 載入 System.Drawing 組件
Add-Type -AssemblyName System.Drawing

# 將圖片切成IG九宮格
function Split-ImgToInstagramGrid {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,
        
        [Alias("o")]
        [string]$Output,
        
        [Alias("b")]
        [int[]]$BgColor = @(255, 255, 255),

        [Alias("f")]
        [ValidateSet("square", "rectangle")]
        [string]$Layout  = "square"
    )
    
    # 偏移量 (防止計算誤差出現白邊)
    $CUT_OFFSET = 5
    
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
        $Output = "output_$timestamp"
    }
        
    # 將路徑轉換為絕對路徑
    $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $Output = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Output)
    
    # 建立輸出目錄
    New-Item -ItemType Directory -Force -Path $Output | Out-Null
    
    # 檢查輸入檔案是否存在
    if (-not (Test-Path $Path)) { throw "輸入檔案不存在：$Path" }

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
        $tileW = $targetW / 3
        $tileH = $targetH / 3
        
        for ($row = 2; $row -ge 0; $row--) {
            for ($col = 2; $col -ge 0; $col--) {
                $left = $col * $tileW
                $upper = $row * $tileH
                
                # 根據指定比例補白
                $targetRatio = $OUTPUT_RATIO_WIDTH / $OUTPUT_RATIO_HEIGHT
                
                # 取長邊為基準
                if ($tileW -gt $tileH) {
                    # 如果寬度較長，以寬度為基準
                    $finalW = $tileW
                    $finalH = $finalW / $targetRatio
                } else {
                    # 如果高度較長，以高度為基準
                    $finalW = $finalH * $targetRatio
                    $finalH = $tileH
                }
                
                # 確保尺寸為正偶數
                $finalW = [Math]::Max(2, [Math]::Ceiling($finalW) -bxor 1)
                $finalH = [Math]::Max(2, [Math]::Ceiling($finalH) -bxor 1)
                
                # 建立新的畫布
                $tile = New-Object System.Drawing.Bitmap($finalW, $finalH)
                $tileGraphics = [System.Drawing.Graphics]::FromImage($tile)
                $tileGraphics.Clear([System.Drawing.Color]::FromArgb($BgColor[0], $BgColor[1], $BgColor[2]))
                
                # 計算置中位置
                $padW = [Math]::Max(0, [Math]::Floor(($finalW - $tileW) / 2))
                $padH = [Math]::Max(0, [Math]::Floor(($finalH - $tileH) / 2))
                
                # 複製到新畫布
                $tileGraphics.DrawImage($newImg, 
                    [System.Drawing.Rectangle]::new($padW, $padH, $tileW, $tileH),
                    [System.Drawing.Rectangle]::new($left, $upper, $tileW, $tileH),
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
        
        Write-Host "處理完成！輸出目錄：$Output"
        Write-Host "檔案列表："
        Get-ChildItem $Output | ForEach-Object { Write-Host "- $($_.Name)" }
    }
    catch {
        throw
    }
} # Split-ImgToInstagramGrid -Path "Image.jpg" -Output "output"
