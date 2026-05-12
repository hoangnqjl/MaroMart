from PIL import Image, ImageDraw, ImageFont
import os

def create_training_diagram_horizontal():
    # Cấu hình kích thước chiều ngang
    width, height = 1600, 400
    bg_color = (255, 255, 255)
    img = Image.new('RGB', (width, height), color=bg_color)
    draw = ImageDraw.Draw(img)

    # Load font
    try:
        font = ImageFont.truetype("arial.ttf", 14)
        title_font = ImageFont.truetype("arial.ttf", 24)
    except:
        font = ImageFont.load_default()
        title_font = ImageFont.load_default()

    colors = {
        "data": (230, 230, 250), "process": (255, 218, 185),
        "model": (175, 238, 238), "output": (152, 251, 152)
    }

    # Định nghĩa các khối theo chiều ngang (x_center, y_center)
    blocks = [
        (120, 200, "Dữ liệu thô\n(Raw CSV/Text)", colors["data"]),
        (350, 200, "Tiền xử lý\nLàm sạch dữ liệu", colors["process"]),
        (580, 200, "Tokenization\n(Text -> Token ID)", colors["process"]),
        (810, 200, "Embedding\n(ID -> Vectors)", colors["process"]),
        (1040, 200, "Transformer Model\n(ViT5 Training)", colors["model"]),
        (1270, 200, "Optimization\n(Backpropagation)", colors["model"]),
        (1500, 200, "Model Hoàn thiện\n(Saved Model)", colors["output"])
    ]

    box_w, box_h = 200, 80
    
    # Vẽ tiêu đề tránh đè lên khối
    draw.text((500, 40), "QUY TRÌNH HUẤN LUYỆN MODEL AI (CHIỀU NGANG)", fill=(0,0,0), font=title_font)

    for i, (x, y, text, color) in enumerate(blocks):
        # Vẽ khối (căn giữa theo x, y)
        left, top = x - box_w//2, y - box_h//2
        draw.rounded_rectangle([left, top, left+box_w, top+box_h], radius=10, fill=color, outline=(80,80,80), width=2)
        
        # Viết chữ căn giữa
        lines = text.split('\n')
        line_y = top + (box_h - len(lines)*18)//2
        for line in lines:
            draw.text((left + 15, line_y), line, fill=(0,0,0), font=font)
            line_y += 18

        # Vẽ mũi tên sang phải
        if i < len(blocks) - 1:
            arrow_start_x = left + box_w
            arrow_end_x = blocks[i+1][0] - box_w//2
            draw.line([arrow_start_x, y, arrow_end_x, y], fill=(150,150,150), width=3)
            # Đầu mũi tên
            draw.polygon([arrow_end_x, y, arrow_end_x-10, y-6, arrow_end_x-10, y+6], fill=(150,150,150))

    output_dir = '../image_report'
    if not os.path.exists(output_dir): os.makedirs(output_dir)
    img.save(os.path.join(output_dir, 'ai_training_workflow_horizontal.png'))
    print("Success! Horizontal diagram saved.")

if __name__ == "__main__":
    create_training_diagram_horizontal()
