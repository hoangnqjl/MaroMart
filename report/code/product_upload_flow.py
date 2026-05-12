import os
import matplotlib.pyplot as plt
import matplotlib.patches as patches

import os
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.colors import LinearSegmentedColormap

def create_product_upload_flow():
    # Set up the figure for landscape orientation
    fig, ax = plt.subplots(figsize=(16, 8), dpi=300)
    ax.set_xlim(0, 20)
    ax.set_ylim(0, 10)
    ax.axis('off')

    # Modern Color Palette (Tailwind-like)
    colors = {
        'bg': '#F8FAFC',
        'border': '#E2E8F0',
        'text_main': '#1E293B',
        'text_sub': '#64748B',
        'step_ai_heavy': '#EEF2FF', # Indigo 50
        'step_ai_heavy_border': '#6366F1', # Indigo 500
        'step_n8n': '#FFF7ED', # Orange 50
        'step_n8n_border': '#F97316', # Orange 500
        'start_end': '#F1F5F9', # Slate 100
        'start_end_border': '#94A3B8', # Slate 400
        'accent': '#0EA5E9' # Sky 500
    }

    fig.patch.set_facecolor(colors['bg'])

    def draw_styled_box(x, y, width, height, title, content, bg_color, border_color):
        # Shadow effect (offset box)
        shadow = patches.FancyBboxPatch((x+0.04, y-0.04), width, height, boxstyle="round,pad=0.1", 
                                         facecolor='#000000', alpha=0.03, zorder=1)
        ax.add_patch(shadow)
        
        # Main Box
        rect = patches.FancyBboxPatch((x, y), width, height, boxstyle="round,pad=0.1", 
                                       facecolor=bg_color, edgecolor=border_color, linewidth=1.5, zorder=2)
        ax.add_patch(rect)
        
        # Text alignment adjustments
        ax.text(x + width/2, y + height - 0.45, title, ha='center', va='center', 
                fontsize=10, fontweight='bold', color=border_color, zorder=4)
        
        # Split content by line for better control if needed, but simple text works if centered well
        ax.text(x + width/2, y + (height-0.6)/2 + 0.1, content, ha='center', va='center', 
                fontsize=8.5, color=colors['text_main'], linespacing=1.6, zorder=4)

    def draw_styled_arrow(x, y, dx, dy):
        ax.annotate('', xy=(x + dx, y + dy), xytext=(x, y),
                    arrowprops=dict(arrowstyle='-|>', color=colors['start_end_border'], 
                                   lw=1.5, mutation_scale=15), zorder=1)

    # ---------------------------------------------------------
    # LAYOUT COORDINATES (Horizontal)
    # ---------------------------------------------------------
    y_center = 4.5
    box_w = 3.6  # Slightly wider
    box_h = 2.8  # Slightly taller
    gap = 0.6    # Slightly tighter gap
    start_x = 0.3

    # 1. Start Node
    draw_styled_box(start_x, y_center, 2.4, 1.6, "INPUT", "Người dùng upload\nẢnh & Tên SP", 
                    colors['start_end'], colors['start_end_border'])
    draw_styled_arrow(start_x + 2.4 + 0.05, y_center + 0.8, gap - 0.1, 0)

    # 2. Step 1 (Gemma 31B)
    x1 = start_x + 2.4 + gap
    draw_styled_box(x1, y_center - 0.6, box_w, box_h, "BƯỚC 1: VISION AI", 
                    "Gemma 4 31B it\n---\nPhân loại Ảnh Thực tế\nvs Ảnh Stock/Web.\nKiểm tra Watermark.", 
                    colors['step_ai_heavy'], colors['step_ai_heavy_border'])
    draw_styled_arrow(x1 + box_w + 0.05, y_center + 0.8, gap - 0.1, 0)

    # 3. Step 2 (Gemma 31B)
    x2 = x1 + box_w + gap
    draw_styled_box(x2, y_center - 0.6, box_w, box_h, "BƯỚC 2: NLP EXTRACTION", 
                    "Gemma 4 31B it\n---\nTrích xuất Brand, Model,\nCategory từ tên SP.\nChuẩn hóa Metadata.", 
                    colors['step_ai_heavy'], colors['step_ai_heavy_border'])
    draw_styled_arrow(x2 + box_w + 0.05, y_center + 0.8, gap - 0.1, 0)

    # 4. Step 3 (N8N + 26B)
    x3 = x2 + box_w + gap
    draw_styled_box(x3, y_center - 0.6, box_w, box_h, "BƯỚC 3: AUTO CONTENT", 
                    "N8N & Gemma 4 26B\n---\nTự động gen mô tả,\nĐiền thuộc tính SP,\nTối ưu SEO & Marketing.", 
                    colors['step_n8n'], colors['step_n8n_border'])
    draw_styled_arrow(x3 + box_w + 0.05, y_center + 0.8, gap - 0.1, 0)

    # 5. Step 4 (N8N + 26B)
    x4 = x3 + box_w + gap
    draw_styled_box(x4, y_center - 0.6, box_w, box_h, "BƯỚC 4: MODERATION", 
                    "N8N & Gemma 4 26B\n---\nKiểm duyệt Spam,\nContent nhạy cảm,\nVi phạm chính sách.", 
                    colors['step_n8n'], colors['step_n8n_border'])
    draw_styled_arrow(x4 + box_w + 0.05, y_center + 0.8, gap - 0.1, 0)

    # 6. End Node
    x5 = x4 + box_w + gap
    draw_styled_box(x5, y_center, 2.4, 1.6, "PUBLISHED", "Sản phẩm hiển thị\ntrên MaroMart", 
                    colors['start_end'], colors['accent'])

    # ---------------------------------------------------------
    # Header & Footer
    # ---------------------------------------------------------
    ax.text(10, 9.2, "HỆ THỐNG TỰ ĐỘNG HÓA QUY TRÌNH ĐĂNG TẢI SẢN PHẨM (MAROMART)", 
            ha='center', fontsize=16, fontweight='bold', color=colors['text_main'])
    ax.text(10, 8.7, "Quy trình tích hợp Vision AI, NLP Model (Gemma) và Workflow Automation (N8N)", 
            ha='center', fontsize=11, color=colors['text_sub'])
    
    # Legend/Tech Stack
    footer_y = 0.8
    ax.text(1, footer_y, "TECH STACK:", fontsize=9, fontweight='bold', color=colors['text_sub'])
    ax.text(3.5, footer_y, "• Vision & Heavy NLP: Gemma 4 31B", fontsize=9, color=colors['step_ai_heavy_border'])
    ax.text(8.5, footer_y, "• Workflow & Light NLP: N8N + Gemma 4 26B", fontsize=9, color=colors['step_n8n_border'])
    ax.text(14.5, footer_y, "• Infrastructure: MaroMart Server (Node.js/Prisma)", fontsize=9, color=colors['accent'])

    # Final adjustments
    image_dir = os.path.join(os.path.dirname(__file__), '..', 'image_report')
    output_path = os.path.join(image_dir, 'product_upload_flow.png')
    
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor=colors['bg'])
    plt.close()
    
    print(f"Flowchart (Horizontal & Aesthetic) generated at: report/image_report/product_upload_flow.png")

if __name__ == "__main__":
    try:
        create_product_upload_flow()
    except Exception as e:
        print(f"An error occurred: {e}")
