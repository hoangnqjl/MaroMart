from PIL import Image, ImageDraw, ImageFont
import os

def create_workflow_diagram():
    # Cấu hình kích thước và màu sắc
    width, height = 1200, 300
    bg_color = (255, 255, 255)
    box_color_1 = (209, 232, 255)  # Light Blue
    box_color_2 = (255, 242, 204)  # Light Yellow
    box_color_3 = (213, 232, 212)  # Light Green
    border_color = (100, 100, 100)
    text_color = (0, 0, 0)

    # Tạo ảnh mới
    img = Image.new('RGB', (width, height), color=bg_color)
    draw = ImageDraw.Draw(img)

    # Cố gắng load font, nếu không có thì dùng font mặc định
    try:
        # Thử tìm font Arial trên Windows
        font = ImageFont.truetype("arial.ttf", 16)
        title_font = ImageFont.truetype("arial.ttf", 18)
    except:
        font = ImageFont.load_default()
        title_font = ImageFont.load_default()

    # Định nghĩa các bước
    steps = [
        "1.1: Phân tích & Gợi ý\nDanh mục (AI Gemma)",
        "1.2: Trích xuất Thuộc tính\ntự động (N8N Webhook)",
        "2.1: Tối ưu Nội dung &\nMô tả (AI Gemma)",
        "2.2: Kiểm duyệt &\nĐăng tải (Hệ thống)"
    ]

    box_w, box_h = 240, 100
    margin = 40
    start_x = 50
    start_y = (height - box_h) // 2

    # Vẽ các box và mũi tên
    for i, step in enumerate(steps):
        x = start_x + i * (box_w + margin)
        y = start_y
        
        # Xác định màu sắc theo giai đoạn
        color = box_color_1 if i < 2 else (box_color_2 if i == 2 else box_color_3)
        
        # Vẽ Box
        draw.rounded_rectangle([x, y, x + box_w, y + box_h], radius=10, fill=color, outline=border_color, width=2)
        
        # Viết chữ (Căn giữa đơn giản)
        lines = step.split('\n')
        line_y = y + 30
        for line in lines:
            draw.text((x + 15, line_y), line, fill=text_color, font=font)
            line_y += 25

        # Vẽ mũi tên kết nối (trừ box cuối)
        if i < len(steps) - 1:
            arrow_start_x = x + box_w
            arrow_start_y = y + box_h // 2
            arrow_end_x = arrow_start_x + margin
            draw.line([arrow_start_x, arrow_start_y, arrow_end_x, arrow_start_y], fill=border_color, width=3)
            # Đầu mũi tên
            draw.polygon([arrow_end_x, arrow_start_y, arrow_end_x-10, arrow_start_y-5, arrow_end_x-10, arrow_start_y+5], fill=border_color)

    # Đảm bảo thư mục tồn tại
    output_dir = '../image_report'
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Lưu ảnh
    output_path = os.path.join(output_dir, 'product_ai_workflow.png')
    img.save(output_path)
    print(f"Success! Diagram rendered and saved to: report/image_report/product_ai_workflow.png")

if __name__ == "__main__":
    create_workflow_diagram()
