import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from "dotenv";
import { safeParseJSON } from "./moderateContent";

dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

/**
 * Kiểm duyệt tất cả field text của user
 * @param fields object key:value, key là tên field, value là text người dùng nhập
 * @returns object: { fieldName: { isSafe: boolean, reason: string } }
 */
export async function moderateUserInputFields(fields: Record<string, string>) {
  const results: Record<
    string,
    { isSafe: boolean; reason: string; raw?: string }
  > = {};

  for (const [fieldName, text] of Object.entries(fields)) {
    console.log(`\n--- Moderating field: ${fieldName} ---`);
    console.log(`Input text: ${text}`);

    const prompt = `
You are a strict content moderation system.

MANDATORY RULES:
- Reject any: NSFW, violence, weapons, drugs, phone numbers, social links, hate speech.
- Reject offensive or vulgar words in any language, e.g., "lồn", "cặc", "địt", etc.
- Reject spam or meaningless content.

SPAM RULES:
- Random keyboard mash (e.g., "agfwighqew", "qyugdfiqư", "qưyhfeyh")
- Nonsense repeated characters (e.g., "tets t5est test", "aaaaaaa", "123123123")
- Repeated meaningless words without context

EXCEPTIONS:
- Do NOT reject content that contains "no", "No", or "không".

Return ONLY JSON : 
{
  "isSafe": true or false,
  "reason": "Short reason (lý do có hỗ trợ đa ngôn ngữ - ví dụ người dùng nhập tiếng Việt thì tiếng Việt - Anh thì tiếng Anh, tương tự) with suggestion if claim is wrong. Use 'Valid' if safe"
}

Content to moderate (field: ${fieldName}): """${text}"""
`;

    try {
      const model = genAI.getGenerativeModel({
        model: "gemini-2.5-flash",
        generationConfig: { responseMimeType: "application/json" }
      });

      const responseAI = await model.generateContent(prompt);
      const json = responseAI.response.text().trim();
      console.log(`Raw AI response: ${json}`);

      const parsed = safeParseJSON(json);

      if (!parsed) {
        results[fieldName] = {
          isSafe: false,
          reason: "AI returned invalid JSON",
          raw: json
        };
        console.log(`Parsed result: Invalid JSON`);
      } else {
        results[fieldName] = parsed;
        console.log(`Parsed result:`, parsed);
      }
    } catch (err: any) {
      results[fieldName] = {
        isSafe: false,
        reason: "Moderation error: " + err.message,
        raw: undefined
      };
      console.log(`Error during moderation: ${err.message}`);
    }
  }

  return results;
}
