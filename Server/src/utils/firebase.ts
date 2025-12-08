// src/utils/firebase.ts
import admin from 'firebase-admin';
import serviceAccount from '../modules/auth/serviceAccountKey.json';

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
    storageBucket: 'maromart-firebase.appspot.com' // THAY BẰNG BUCKET CỦA BẠN
  });
}

export const bucket = admin.storage().bucket();
export const auth = admin.auth();