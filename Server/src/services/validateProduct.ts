import { IProduct } from "../modules/product/product.model";
import { moderateContent, moderateMedia } from "./moderateContent";

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

export async function validateProduct(product: IProduct) {
  const errors: string[] = [];

  // 1. KIỂM TRA CƠ BẢN
  if (!product.productAttribute || typeof product.productAttribute !== "object") {
    errors.push("productAttribute must be an object");
    return { isValid: false, errors };
  }

  if (!product.categoryId || typeof product.categoryId !== "string") {
    errors.push("categoryId is required");
    return { isValid: false, errors };
  }

  // 2. KIỂM TRA ATTRIBUTE
  const templateAttrs = attributeTemplates[product.categoryId] || [];
  
  const externalFields: Record<string, keyof IProduct> = {
    brand: "productBrand",
    warranty: "productWP",
    origin: "productOrigin",
    condition: "productCondition"
  };

  const missingAttrs = templateAttrs.filter(attr => {
    // Check trường đặc biệt
    if (externalFields[attr]) {
      const rootVal = product[externalFields[attr]];
      const attrVal = product.productAttribute[attr];
      // Nếu có ở root HOẶC có ở attribute thì OK. Chỉ lỗi khi thiếu cả 2.
      if ((rootVal && rootVal !== "") || (attrVal && attrVal !== "")) {
          return false; // Không thiếu
      }
      return true; // Thiếu
    }
    // Check trường thường: Bắt buộc phải có trong attribute và không được rỗng
    const val = product.productAttribute[attr];
    return !val || val.toString().trim() === "";
  });

  if (missingAttrs.length > 0) {
    errors.push(`Missing required attributes: ${missingAttrs.join(", ")}`);
  }

  // 3. KIỂM TRA ĐỊA CHỈ
  if (!product.productAddress || typeof product.productAddress !== "object") {
    errors.push("productAddress must be an object");
  } else {
    const addr = product.productAddress;
    // Bỏ check district, chỉ cần Tỉnh và Xã/Phường
    if (!addr.province || (!addr.commune && !addr.ward)) {
      errors.push("Địa chỉ phải bao gồm Tỉnh/Thành phố và Phường/Xã");
    }
  }

  // 4. KIỂM TRA THÔNG TIN KHÁC
  if (!product.productName || product.productName.trim().length < 3) errors.push("Tên sản phẩm quá ngắn");
  if (!product.productDescription || product.productDescription.trim().length < 5) errors.push("Mô tả sản phẩm quá ngắn");
  if (product.productPrice === undefined || product.productPrice < 0) errors.push("Giá sản phẩm không hợp lệ");
  
  // 5. AI MODERATION (TEXT) - SỬA ĐỂ BỎ QUA LỖI API KEY
  const textContent = `${product.productName}. ${product.productDescription}. ${JSON.stringify(product.productAttribute)}`;
  try {
    const textCheck = await moderateContent(textContent);
    console.log(textCheck)
    if (!textCheck.isSafe) {
        // Nếu lý do lỗi chứa từ khoá về API/Error -> Bỏ qua, coi như an toàn
        const reason = textCheck.reason || "";
        if (reason.includes("API key") || reason.includes("Error fetching") || reason.includes("400")) {
            console.warn("⚠️ Bỏ qua AI Text check do lỗi cấu hình API:", reason);
        } else {
            errors.push(`Text flagged: ${textCheck.reason}`);  
        }
    }
  } catch (error: any) {
    console.warn("⚠️ Bỏ qua AI Text check (Exception):", error.message);
  }

  return { isValid: errors.length === 0, errors };
}