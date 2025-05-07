from PIL import Image, ImageOps
import os
import argparse
from datetime import datetime

# Instagram 首頁顯示比例常數
IG_PREVIEW_WIDTH = 307.670
IG_PREVIEW_HEIGHT = 410.223
IG_PREVIEW_RATIO = IG_PREVIEW_HEIGHT / IG_PREVIEW_WIDTH

def process_image(input_path, output_dir=None, bg_color=(255,255,255), pad_to_square_flag=False):
    """處理圖片並輸出九宮格"""
    # 建立輸出目錄
    if output_dir is None:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_dir = f'output_{timestamp}'
    os.makedirs(output_dir, exist_ok=True)

    # 讀取圖片並補白成 Instagram 首頁顯示比例
    img = Image.open(input_path)
    target_w = img.width
    target_h = int(target_w * IG_PREVIEW_RATIO)
    
    # 如果原始高度已經超過目標高度，則以高度為基準
    if img.height > target_h:
        target_h = img.height
        target_w = int(target_h / IG_PREVIEW_RATIO)
    
    # 補白
    pad_w = (target_w - img.width) // 2
    pad_h = (target_h - img.height) // 2
    img = ImageOps.expand(img, (pad_w, pad_h, target_w-img.width-pad_w, target_h-img.height-pad_h), fill=bg_color)

    # 切成九宮格
    w, h = img.size
    tile_w, tile_h = w // 3, h // 3
    for row in range(2, -1, -1):
        for col in range(2, -1, -1):
            left = col * tile_w
            upper = row * tile_h
            right = left + tile_w
            lower = upper + tile_h
            tile = img.crop((left, upper, right, lower))
            
            # 如果需要補白成正方形
            if pad_to_square_flag:
                size = max(tile.width, tile.height)
                pad_w = (size - tile.width) // 2
                pad_h = (size - tile.height) // 2
                tile = ImageOps.expand(tile, (pad_w, pad_h, size-tile.width-pad_w, size-tile.height-pad_h), fill=bg_color)
            
            # 儲存九宮格圖片
            tile_num = (2-row) * 3 + (2-col) + 1
            tile_path = os.path.join(output_dir, f'grid_{tile_num}.jpg')
            tile.save(tile_path)

    return output_dir

def main():
    parser = argparse.ArgumentParser(description='將圖片切成IG九宮格')
    parser.add_argument('input', help='輸入圖片路徑')
    parser.add_argument('--output', '-o', help='輸出目錄')
    parser.add_argument('--bg-color', '-b', nargs=3, type=int, default=[255,255,255],
                      help='背景顏色 (RGB)，預設為白色 (255 255 255)')
    parser.add_argument('--pad-to-square', '-p', action='store_true',
                      help='將九宮格圖片補白成正方形')
    args = parser.parse_args()

    try:
        output_dir = process_image(args.input, args.output, tuple(args.bg_color), args.pad_to_square)
        print(f'處理完成！輸出目錄：{output_dir}')
        print('檔案列表：')
        for file in os.listdir(output_dir):
            print(f'- {file}')
    except Exception as e:
        print(f'錯誤：{str(e)}')

if __name__ == '__main__':
    main() 