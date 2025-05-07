# 載入 System.Drawing 組件
Add-Type -AssemblyName System.Drawing

# 將圖片切成IG九宮格
function Convert-ToInstagramGrid {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,
        
        [Alias("o")]
        [string]$Output,
        
        [Alias("b")]
        [int[]]$BgColor = @(255, 255, 255),
        
        [Alias("k")]
        [switch]$KeepOriginalRatio,

        [Alias("p")]
        [int[]]$Padding = @(0, 0, 0, 0)
    )
    
    # Instagram 首頁顯示比例常數
    # $IG_PREVIEW_WIDTH = 307.670 + 3.5
    # $IG_PREVIEW_HEIGHT = 410.223
    $IG_PREVIEW_WIDTH = 1012.5
    $IG_PREVIEW_HEIGHT = 1350
    
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
    if (-not (Test-Path $Path)) {
        throw "輸入檔案不存在：$Path"
    }

    # 處理補邊參數
    $paddingValues = switch ($Padding.Count) {
        1 { @($Padding[0], $Padding[0], $Padding[0], $Padding[0]) }
        2 { @($Padding[0], $Padding[1], $Padding[0], $Padding[1]) }
        3 { @($Padding[0], $Padding[1], $Padding[2], $Padding[1]) }
        4 { $Padding }
        default { @(0, 0, 0, 0) }
    }

    try {
        # 讀取圖片
        $img = [System.Drawing.Image]::FromFile($Path)
        
        # 計算目標尺寸
        $targetW = $img.Width
        $targetH = [Math]::Ceiling($targetW * $IG_PREVIEW_HEIGHT / $IG_PREVIEW_WIDTH)
        
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
                
                # 建立九宮格圖片
                $tile = New-Object System.Drawing.Bitmap($tileW, $tileH)
                $tileGraphics = [System.Drawing.Graphics]::FromImage($tile)
                $tileGraphics.Clear([System.Drawing.Color]::FromArgb($BgColor[0], $BgColor[1], $BgColor[2]))
                
                # 複製對應區域
                $tileGraphics.DrawImage($newImg, 
                    [System.Drawing.Rectangle]::new(0, 0, $tileW, $tileH),
                    [System.Drawing.Rectangle]::new($left, $upper, $tileW, $tileH),
                    [System.Drawing.GraphicsUnit]::Pixel)
                
                # 預設補白成正方形，除非指定保持原始比例
                if (-not $KeepOriginalRatio) {
                    $size = [Math]::Max($tileW, $tileH)
                    $squareTile = New-Object System.Drawing.Bitmap($size, $size)
                    $squareGraphics = [System.Drawing.Graphics]::FromImage($squareTile)
                    $squareGraphics.Clear([System.Drawing.Color]::FromArgb($BgColor[0], $BgColor[1], $BgColor[2]))
                    
                    $padW = ($size - $tileW) / 2
                    $padH = ($size - $tileH) / 2
                    $squareGraphics.DrawImage($tile, $padW, $padH, $tileW, $tileH)
                    
                    $tile.Dispose()
                    $tile = $squareTile
                }

                # 加入補邊
                $finalWidth = $tile.Width + $paddingValues[1] + $paddingValues[3]  # 右 + 左
                $finalHeight = $tile.Height + $paddingValues[0] + $paddingValues[2]  # 上 + 下
                
                $finalTile = New-Object System.Drawing.Bitmap($finalWidth, $finalHeight)
                $finalGraphics = [System.Drawing.Graphics]::FromImage($finalTile)
                $finalGraphics.Clear([System.Drawing.Color]::FromArgb($BgColor[0], $BgColor[1], $BgColor[2]))
                
                # 繪製原始圖片到補邊後的畫布上
                $finalGraphics.DrawImage($tile, $paddingValues[3], $paddingValues[0], $tile.Width, $tile.Height)
                
                # 儲存九宮格圖片
                $tileNum = (2 - $row) * 3 + (2 - $col) + 1
                $tilePath = Join-Path $Output "grid_$tileNum.jpg"
                $finalTile.Save($tilePath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                
                # 釋放資源
                $tile.Dispose()
                $tileGraphics.Dispose()
                $finalTile.Dispose()
                $finalGraphics.Dispose()
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
        throw "處理圖片時發生錯誤：$_"
    }
}

Convert-ToInstagramGrid -Path "Image.jpg" -Output "output" -KeepOriginalRatio -Padding @(0, 33.5, 0)
