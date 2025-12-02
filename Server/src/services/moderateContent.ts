import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from "dotenv";

dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

export async function moderateContent(text: string) {
  try {
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
      generationConfig: { responseMimeType: "application/json" }
    });
    const prompt = `
    You are a strict content moderation system.
    MANDATORY RULES:
    Reject any: NSFW, violence, weapons, drugs, phone numbers, social links, hate speech.

    Return ONLY:
    {
      "isSafe": true or false,
      "reason": "Short reason in English with suggestion if claim is wrong. Use 'Valid' if safe"
    }

    Content: """${text}"""
    `;
    const response = await model.generateContent(prompt);
    const json = response.response.text().trim();
    const parsed = safeParseJSON(json);

    if (!parsed) {
      return {
        isSafe: false,
        reason: "AI returned invalid JSON",
        raw: json
      };
    }

    return parsed;
  } catch (err: any) {
    return {
      isSafe: false,
      reason: "Moderation error: " + err.message
    };
  }
}


export function safeParseJSON(raw: string) {
  try {
    return JSON.parse(raw);
  } catch {
    try {
      const fixed = raw.replace(/,\s*}/g, "}").replace(/,\s*]/g, "]");
      return JSON.parse(fixed);
    } catch {
      return null;
    }
  }
}

/**
 * Kiểm duyệt ảnh bằng Gemini 2.5 Flash (model mới nhất 2025)
 * Fix lỗi decode: Chỉ gửi base64 raw + mimeType riêng
 */
export async function moderateMedia(
  base64Images: string[],
  category: string,
  productName: string
): Promise<{ isSafe: boolean; reason: string }> {

  if (!base64Images?.length) {
    return { isSafe: false, reason: "Không có ảnh để kiểm duyệt" };
  }
  if (!category?.trim() || !productName?.trim()) {
    return { isSafe: false, reason: "Thiếu danh mục hoặc tên sản phẩm" };
  }

  try {
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",           // đúng model bạn muốn
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0,
      },
    });

    const prompt = `Bạn là chuyên gia kiểm định sản phẩm cực kỳ chính xác cho sàn TMĐT.

Danh mục: "${category}"
Tên sản phẩm: "${productName}"

Kiểm tra tất cả ảnh:
1. Cấm tuyệt đối (vi phạm 1 ảnh → từ chối):
   • Khỏa thân, khiêu dâm, nội dung người lớn
   • Bạo lực, máu me, vũ khí, ma túy, rượu bia, thuốc lá
   • Động vật sống (chó, mèo, chim, cá…)
   • Chính trị, tôn giáo, thù hận
   • Số điện thoại, Zalo/FB, website in ảnh
   • Ảnh người (kể cả người cầm sản phẩm)

2. Ảnh phải đúng sản phẩm thật "${productName}" trong danh mục "${category}"
   • Phải đúng thương hiệu & model (MacBook → không được Asus, iPhone → không được Samsung…)
   • Không được ảnh minh họa, ảnh Google

Trả về đúng 1 JSON duy nhất, không thêm chữ:

{"isSafe":true|false,"reason":"Lý do ngắn gọn tiếng Việt hoặc 'Hợp lệ'" - không viết hoa chữ cái đầu}`;

    const imageParts = base64Images.map(dataUri => ({
      inlineData: {
        data: dataUri.split(',')[1],
        mimeType: dataUri.split(';')[0].split(':')[1] === 'application/octet-stream'
          ? 'image/jpeg'
          : dataUri.split(';')[0].split(':')[1] || 'image/jpeg'
      }
    }));

    const result = await model.generateContent([prompt, ...imageParts]);
    const text = result.response.text().trim();

    const parsed = JSON.parse(text);

    if (typeof parsed.isSafe !== "boolean") {
      return { isSafe: false, reason: "Phản hồi AI không đúng định dạng" };
    }

    return {
      isSafe: parsed.isSafe,
      reason: parsed.reason || (parsed.isSafe ? "Hợp lệ" : "Ảnh vi phạm hoặc không đúng sản phẩm")
    };

  } catch (error: any) {
    // Trả về reason thật sự – bạn sẽ thấy chính xác lỗi gì ở client
    const msg = error?.message || String(error);
    return { 
      isSafe: false, 
      reason: msg.includes("gemini-2.5-flash") 
        ? "Gemini-2.5-flash chưa khả dụng ở region của bạn" 
        : `Lỗi AI: ${msg}`
    };
  }
}