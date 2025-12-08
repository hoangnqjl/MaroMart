import { Request, Response } from "express";
import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from "dotenv";
import { safeParseJSON } from "./moderateContent";

dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

const attributeTemplates: Record<string, string[]> = {
  auto: ["brand","model","year","fuel_type","transmission","mileage","condition","color","accessories_type","warranty"],
  furniture: ["material","color","dimensions","style","room_type","weight","brand","warranty","assembly_required"],
  technology: ["brand","model","cpu","ram","storage","screen_size","battery_capacity","os","connectivity","warranty"],
  office: ["material","dimensions","color","brand","quantity","type","weight"],
  style: ["size","color","material","gender","brand","season","pattern","style","origin"],
  service: ["service_type","duration","price_type","provider","area","availability","warranty"],
  hobby: ["category","skill_level","material","brand","age_range","weight","size"],
  kids: ["age_range","material","size","color","brand","education_type","certification","weight"]
};

// Route handler
export async function attributeSuggest(req: Request, res: Response) {
  try {
    const { productName, description, condition } = req.body;

    if (!productName || !description || !condition) {
      return res.status(400).json({
        category: null,
        attributes: null,
        reason: "Missing required fields: productName, description, condition"
      });
    }

    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
      generationConfig: { responseMimeType: "application/json" }
    });

    const prompt = `
        You are a product attribute suggestion engine.

        Your tasks:
        1. Identify the most suitable product category from this list:
        [auto, furniture, technology, office, style, service, hobby, kids]

        2. Using the detected category, generate all attributes based on this template list:

        ${JSON.stringify(attributeTemplates, null, 2)}

        3. Fill in each attribute using:
        - Product name
        - Description
        - Condition
        - Search for additional public information if needed to fill attributes.

        Rules:
        - If you cannot find or infer a value for an attribute, return "no" instead of null.
        - Keep all values short.
        - Do NOT hallucinate impossible details.
        - "condition" must always be returned exactly as user provided.

        Return ONLY this JSON format:
        {
        "category": string,
        "attributes": { key: value | "no" },
        "reason": "short explanation (lý do có hỗ trợ đa ngôn ngữ - ví dụ người dùng nhập tiếng Việt thì tiếng Việt - Anh thì tiếng Anh, tương tự)"
        }

        Product Info:
        - Name: ${productName}
        - Description: ${description}
        - Condition: ${condition}
        `;


    const responseAI = await model.generateContent(prompt);
    const json = responseAI.response.text().trim();
    const parsed = safeParseJSON(json);

    if (!parsed) {
      return res.status(500).json({
        category: null,
        attributes: null,
        reason: "AI returned invalid JSON",
        raw: json
      });
    }

    return res.json(parsed);
  } catch (err: any) {
    return res.status(500).json({
      category: null,
      attributes: null,
      reason: "Attribute suggestion error: " + err.message
    });
  }
}

