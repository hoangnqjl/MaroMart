// backend/src/utils/onedrive.ts
import axios from 'axios';
import * as fs from 'fs';
import 'dotenv/config';
import * as path from 'path';

interface TokenResponse {
    access_token: string;
    expires_in: number;
}

// KHAI BÁO BIẾN TOÀN CỤC (Sửa lỗi ReferenceError)
const {
    CLIENT_ID,
    CLIENT_SECRET,
    TENANT_ID,
    USER_EMAIL,
    FOLDER_NAME
} = process.env;

const TOKEN_URL = `https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token`;
let cachedToken: string | null = null;
let tokenExpires: number = 0;
// KẾT THÚC KHAI BÁO BIẾN TOÀN CỤC

// Lấy token (Giữ nguyên)
const getToken = async (): Promise<string> => {
    if (cachedToken && Date.now() < tokenExpires) return cachedToken;
    // ... (Logic lấy token)
    const params = new URLSearchParams({
        client_id: CLIENT_ID!,
        client_secret: CLIENT_SECRET!,
        scope: 'https://graph.microsoft.com/.default',
        grant_type: 'client_credentials'
    });
    const { data } = await axios.post<TokenResponse>(TOKEN_URL, params);
    cachedToken = data.access_token;
    tokenExpires = Date.now() + data.expires_in * 1000 - 300000;
    return cachedToken;
};

// Kiểm tra folder (Giữ nguyên)
const ensureFolder = async (token: string): Promise<string> => {
    const url = `https://graph.microsoft.com/v1.0/users/${USER_EMAIL}/drive/root/children`;
    // ... (Logic kiểm tra và tạo folder)
    const { data } = await axios.get<any>(url, { headers: { Authorization: `Bearer ${token}` } });
    const folder = data.value.find((item: any) => item.name === FOLDER_NAME && item.folder);
    if (folder) return folder.id;
    const createRes = await axios.post(
        `https://graph.microsoft.com/v1.0/users/${USER_EMAIL}/drive/root/children`,
        { name: FOLDER_NAME, folder: {} },
        { headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' } }
    );
    return createRes.data.id;
};

/**
 * Lấy Direct Download URL của file bằng Item ID.
 * @param token Access token.
 * @param fileItemId ID của file trên OneDrive.
 * @returns Direct Download URL.
 */
const getDirectDownloadUrl = async (token: string, fileItemId: string): Promise<string> => {
    // API để lấy chi tiết của Drive Item (bao gồm @microsoft.graph.downloadUrl)
    const url = `https://graph.microsoft.com/v1.0/users/${USER_EMAIL}/drive/items/${fileItemId}`;

    const { data } = await axios.get<any>(url, {
        headers: { Authorization: `Bearer ${token}` }
    });

    // Trả về link tải xuống trực tiếp
    return data['@microsoft.graph.downloadUrl']; 
};

// Upload file và lấy Direct Download URL
export const uploadToMaroMart = async (filePath: string, fileName: string): Promise<string> => {
    const token = await getToken();
    await ensureFolder(token);

    // BƯỚC 1: Upload file và lấy ID của file
    const uploadUrl = `https://graph.microsoft.com/v1.0/users/${USER_EMAIL}/drive/root:/${FOLDER_NAME}/${fileName}:/content`;
    const fileStream = fs.createReadStream(filePath);
    const stats = fs.statSync(filePath);

    // Lấy phản hồi từ PUT để có ID của file
    const uploadRes = await axios.put<any>(uploadUrl, fileStream, {
        headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/octet-stream',
            'Content-Length': stats.size
        },
        maxBodyLength: Infinity
    });

    const fileItemId = uploadRes.data.id;

    // BƯỚC 2: Lấy Direct Download URL bằng Item ID
    const directLink = await getDirectDownloadUrl(token, fileItemId);
    
    // Nếu bạn cũng muốn tạo link chia sẻ công khai (WebUrl - có thể cần nếu file là private):
    // const webLink = await createWebLink(token, fileName); 
    // Nếu file được upload vào Shared Drive/Shared Folder, nó có thể đã là public.
    
    return directLink; // Link TRỰC TIẾP
};

export const uploadMultipleToOneDrive = async (
    files: Express.Multer.File[],
    userId: string,
    productId: string   // ← mới thêm: nhận productId sau khi tạo
): Promise<{ images: string[], videos: string[] }> => {
    if (!files || files.length === 0) return { images: [], videos: [] };

    const token = await getToken();
    
    // Tạo cấu trúc thư mục: userId/products/productId/images + videos
    const basePath = `MaroMart/${userId}/products/${productId}`;
    const imagesFolderId = await ensureFolderByPath(token, `${basePath}/images`);
    const videosFolderId = await ensureFolderByPath(token, `${basePath}/videos`);

    const result = {
        images: [] as string[],
        videos: [] as string[]
    };

    for (const file of files) {
        const ext = path.extname(file.originalname).toLowerCase();
        const isVideo = ['.mp4', '.mov', '.avi', '.mkv', '.webm'].includes(ext);
        
        const folderId = isVideo ? videosFolderId : imagesFolderId;
        const folderPath = isVideo ? `${basePath}/videos` : `${basePath}/images`;

        const safeName = `${Date.now()}_${Math.random().toString(36).substring(2, 8)}${ext}`;
        const uploadUrl = `https://graph.microsoft.com/v1.0/users/${USER_EMAIL}/drive/items/${folderId}:/${safeName}:/content`;

        await axios.put(uploadUrl, fs.createReadStream(file.path), {
            headers: {
                Authorization: `Bearer ${token}`,
                'Content-Type': file.mimetype || 'application/octet-stream',
            },
            maxBodyLength: Infinity
        });

        // Lấy direct link
        const itemUrl = `https://graph.microsoft.com/v1.0/users/${USER_EMAIL}/drive/items/${folderId}:/${safeName}`;
        const { data: item } = await axios.get(itemUrl, { headers: { Authorization: `Bearer ${token}` } });
        const directLink = item['@microsoft.graph.downloadUrl'];

        // THÊM KÝ HIỆU ĐỂ FRONTEND DỄ XỬ LÝ
        if (isVideo) {
            result.videos.push(`video:${directLink}`);      
        } else {
            result.images.push(`image:${directLink}`);
        }

        fs.unlinkSync(file.path); // xóa file tạm
    }

    return result;
};

// export const uploadChatMediaToOneDrive = async (
//     files: Express.Multer.File[],
//     conId: string,
//     messageId: string
// ): Promise<IMessageMedia[]> => {
//     if (!files || files.length === 0) return [];

//     const token = await getToken(); // hàm lấy token của bạn

//     const basePath = `Conversation/${conId}/${messageId}`;
//     const imagesFolderId = await ensureFolderByPath(token, `${basePath}/images`);
//     const videosFolderId = await ensureFolderByPath(token, `${basePath}/videos`);

//     const mediaResult: IMessageMedia[] = [];

//     for (const file of files) {
//         const ext = path.extname(file.originalname).toLowerCase();
//         const isVideo = ['.mp4', '.mov', '.avi', '.mkv', '.webm'].includes(ext);
//         const isAudio = ['.mp3', '.wav', '.ogg', '.m4a'].includes(ext);

//         const folderId = isVideo ? videosFolderId : (isAudio ? videosFolderId : imagesFolderId);
//         const safeName = `${Date.now()}_${Math.random().toString(36).substr(2, 9)}${ext}`;

//         const uploadUrl = `https://graph.microsoft.com/v1.0/me/drive/items/${folderId}:/${safeName}:/content`;
//         await axios.put(uploadUrl, fs.createReadStream(file.path), {
//             headers: {
//                 Authorization: `Bearer ${token}`,
//                 'Content-Type': file.mimetype
//             },
//             maxBodyLength: Infinity
//         });

//         const { data } = await axios.get(
//             `https://graph.microsoft.com/v1.0/me/drive/items/${folderId}:/${safeName}`,
//             { headers: { Authorization: `Bearer ${token}` } }
//         );

//         const directLink = data['@microsoft.graph.downloadUrl'];
//         const type = isVideo ? 'video' : (isAudio ? 'audio' : 'image');

//         mediaResult.push({
//             type,
//             url: `${type}:${directLink}`
//         });

//         fs.unlinkSync(file.path);
//     }

//     return mediaResult;
// };


// Hàm tạo sharing link ban đầu (Nếu bạn vẫn muốn dùng nó để tạo quyền truy cập ẩn danh)
const createSharingLink = async (token: string, fileName: string): Promise<string> => {
    const itemPath = `${FOLDER_NAME}/${fileName}`;
    
    // Sửa lỗi 400: Gọi API này sau khi file đã được upload bằng Path-based addressing có thể gây lỗi. 
    // Thay thế bằng cách tìm kiếm file bằng Path-based addressing trước khi tạo link, 
    // HOẶC sử dụng Item ID từ phản hồi upload (cách an toàn hơn, nhưng đã được tích hợp vào hàm chính).
    
    // Dùng Item ID là cách đáng tin cậy hơn để tạo Link chia sẻ.
    // Tuy nhiên, vì mục tiêu là Direct Download URL, chúng ta đã dùng getDirectDownloadUrl.
    
    // Nếu bạn vẫn muốn sử dụng nó, bạn phải dùng API để lấy ID của item trước.
    
    // Ví dụ sửa lỗi 400: (Cần GET item trước)
    const itemUrl = `https://graph.microsoft.com/v1.0/users/${USER_EMAIL}/drive/root:/${itemPath}`;
    const { data: itemData } = await axios.get<any>(itemUrl, {
        headers: { Authorization: `Bearer ${token}` }
    });
    const fileId = itemData.id;
    
    const url = `https://graph.microsoft.com/v1.0/users/${USER_EMAIL}/drive/items/${fileId}/createLink`;
    
    // ... (phần còn lại của hàm tạo link)
    const body = { type: 'view', scope: 'anonymous' }; // Dùng 'view' nếu 'download' bị lỗi

    const { data } = await axios.post<any>(url, body, {
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }
    });

    return data.link.webUrl; 
};

const ensureFolderByPath = async (token: string, path: string): Promise<string> => {
    const parts = path.split('/').filter(p => p);
    let currentId = (await axios.get(`https://graph.microsoft.com/v1.0/users/${USER_EMAIL}/drive/root`, {
        headers: { Authorization: `Bearer ${token}` }
    })).data.id;

    for (const part of parts) {
        const { data } = await axios.get(
            `https://graph.microsoft.com/v1.0/users/${USER_EMAIL}/drive/items/${currentId}/children`,
            { headers: { Authorization: `Bearer ${token}` } }
        );

        let folder = data.value.find((item: any) => item.name === part && item.folder);
        if (!folder) {
            const createRes = await axios.post(
                `https://graph.microsoft.com/v1.0/users/${USER_EMAIL}/drive/items/${currentId}/children`,
                { name: part, folder: {} },
                { headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' } }
            );
            folder = createRes.data;
        }
        currentId = folder.id;
    }
    return currentId;
};