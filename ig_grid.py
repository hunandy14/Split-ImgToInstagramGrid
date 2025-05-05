from PIL import Image, ImageOps
import os
import argparse
from datetime import datetime

def pad_to_4_5(img, bg_color=(255,255,255)):
    """將圖片補白成4:5比例，保持原始解析度"""
    # 計算目標尺寸（保持原始寬度，高度按4:5比例）
    target_w = img.width
    target_h = int(target_w * 5 / 4)  # 4:5比例
    
    # 如果原始高度已經超過目標高度，則以高度為基準
    if img.height > target_h:
        target_h = img.height
        target_w = int(target_h * 4 / 5)  # 4:5比例
    
    # 補白
    pad_w = (target_w - img.width) // 2
    pad_h = (target_h - img.height) // 2
    img = ImageOps.expand(img, (pad_w, pad_h, target_w-img.width-pad_w, target_h-img.height-pad_h), fill=bg_color)
    return img

def pad_to_square(img, bg_color=(255,255,255)):
    """將圖片補白成正方形，內容居中"""
    size = max(img.width, img.height)
    pad_w = (size - img.width) // 2
    pad_h = (size - img.height) // 2
    return ImageOps.expand(img, (pad_w, pad_h, size-img.width-pad_w, size-img.height-pad_h), fill=bg_color)

def split_to_grid(img, grid=3, bg_color=(255,255,255)):
    """將圖片切成3x3九宮格，從右下角開始，並補白成正方形"""
    w, h = img.size
    tile_w, tile_h = w // grid, h // grid
    tiles = []
    for row in range(grid-1, -1, -1):
        for col in range(grid-1, -1, -1):
            left = col * tile_w
            upper = row * tile_h
            right = left + tile_w
            lower = upper + tile_h
            tile = img.crop((left, upper, right, lower))
            tile = pad_to_square(tile, bg_color)
            tiles.append(tile)
    return tiles

def merge_grid(tiles, grid=3):
    """將九宮格圖片合併回一張大圖"""
    tile_w, tile_h = tiles[0].size
    new_img = Image.new('RGB', (tile_w*grid, tile_h*grid), (255,255,255))
    for idx, tile in enumerate(tiles):
        row, col = divmod(idx, grid)
        new_img.paste(tile, (col*tile_w, row*tile_h))
    return new_img

def process_image(input_path, output_dir=None, bg_color=(255,255,255)):
    """處理圖片並輸出九宮格"""
    # 建立輸出目錄
    if output_dir is None:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_dir = f'output_{timestamp}'
    os.makedirs(output_dir, exist_ok=True)

    # 讀取並處理圖片
    img = Image.open(input_path)
    img_4_5 = pad_to_4_5(img, bg_color)
    
    # 儲存補白後的圖片
    padded_path = os.path.join(output_dir, 'padded.jpg')
    img_4_5.save(padded_path)

    # 切成九宮格
    tiles = split_to_grid(img_4_5, bg_color=bg_color)
    for i, tile in enumerate(tiles):
        tile_path = os.path.join(output_dir, f'grid_{i+1}.jpg')
        tile.save(tile_path)

    # 驗證：拼回一張大圖
    merged = merge_grid(tiles)
    merged_path = os.path.join(output_dir, 'merged.jpg')
    merged.save(merged_path)

    return output_dir

def main():
    parser = argparse.ArgumentParser(description='將圖片切成IG九宮格')
    parser.add_argument('input', help='輸入圖片路徑')
    parser.add_argument('--output', '-o', help='輸出目錄')
    parser.add_argument('--bg-color', '-b', nargs=3, type=int, default=[255,255,255],
                      help='背景顏色 (RGB)，預設為白色 (255 255 255)')
    args = parser.parse_args()

    try:
        output_dir = process_image(args.input, args.output, tuple(args.bg_color))
        print(f'處理完成！輸出目錄：{output_dir}')
        print('檔案列表：')
        for file in os.listdir(output_dir):
            print(f'- {file}')
    except Exception as e:
        print(f'錯誤：{str(e)}')

if __name__ == '__main__':
    main() 