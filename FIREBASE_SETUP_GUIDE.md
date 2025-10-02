# 🔥 Firebase Cloud Setup Guide

## การติดตั้ง Firebase Cloud สำหรับ MyOFFgridApp

### 📋 ขั้นตอนการติดตั้ง

#### 1. สร้าง Firebase Project
1. ไปที่ [Firebase Console](https://console.firebase.google.com/)
2. คลิก "Create a project" หรือ "เพิ่มโปรเจกต์"
3. ตั้งชื่อโปรเจกต์ เช่น "MyOFFgridApp"
4. เลือกการตั้งค่า Analytics (แนะนำให้เปิด)
5. คลิก "Create project"

#### 2. เปิดใช้งาน Authentication
1. ใน Firebase Console ไปที่ **Authentication**
2. คลิก "Get started"
3. ไปที่แท็บ **Sign-in method**
4. เปิดใช้งาน:
   - **Email/Password** (สำหรับ login ปกติ)
   - **Anonymous** (สำหรับ guest users)

#### 3. สร้าง Firestore Database
1. ไปที่ **Firestore Database**
2. คลิก "Create database"
3. เลือก **Start in test mode** (สำหรับ development)
4. เลือก Location ที่ใกล้ที่สุด (แนะนำ: asia-southeast1)

#### 4. เปิดใช้งาน Storage
1. ไปที่ **Storage**
2. คลิก "Get started"
3. เลือก **Start in test mode**
4. เลือก Location เดียวกับ Firestore

#### 5. เพิ่ม Web App
1. ใน Project Overview คลิก **Web icon** (`</>`)
2. ตั้งชื่อ App nickname: "MyOFFgridApp-Web"
3. ✅ เช็ค "Also set up Firebase Hosting"
4. คลิก "Register app"
5. **คัดลอก Config object** ที่ได้

#### 6. อัปเดต Configuration

แทนที่ข้อมูลใน `web/index.html`:

```javascript
// แทนที่ส่วนนี้ด้วยข้อมูลจาก Firebase Console
const firebaseConfig = {
  apiKey: "your-actual-api-key",
  authDomain: "your-project-id.firebaseapp.com",
  projectId: "your-actual-project-id",
  storageBucket: "your-project-id.appspot.com", 
  messagingSenderId: "your-actual-sender-id",
  appId: "your-actual-app-id"
};
```

#### 7. อัปเดต Android Configuration
1. ใน Firebase Console คลิก **Android icon**
2. ใส่ Android package name: `com.example.offgrid_sos_app`
3. ดาวน์โหลด `google-services.json`
4. วางไฟล์ลงใน `android/app/`

#### 8. อัปเดต iOS Configuration
1. ใน Firebase Console คลิก **iOS icon**
2. ใส่ iOS bundle ID: `com.example.offgridSosApp`
3. ดาวน์โหลด `GoogleService-Info.plist`
4. วางไฟล์ลงใน `ios/Runner/`

---

## 🧪 การทดสอบ

### ขั้นตอนการทดสอบ Firebase Integration:

1. **รัน App**:
   ```bash
   flutter run
   ```

2. **ทดสอบ User Registration**:
   - สร้าง user ใหม่ในแอป
   - ดูใน Firebase Console > Authentication ว่ามี user ใหม่
   - ดูใน Firestore > users collection ว่ามีข้อมูล user

3. **ทดสอบ Offline/Online Sync**:
   - สร้าง user ขณะออฟไลน์
   - เชื่อมต่ออินเทอร์เน็ต
   - ตรวจสอบว่าข้อมูล sync ขึ้น cloud

### 📱 การใช้งาน Cloud Sync

```dart
// ตัวอย่างการใช้งานใน UI
await AuthService.instance.signUp(
  name: 'John Doe',
  email: 'john@example.com',
  password: 'secure123', // จำเป็นสำหรับ Firebase
  phone: '+66812345678',
);

// Sync จะทำงานอัตโนมัติเมื่อมีอินเทอร์เน็ต
await AuthService.instance.syncToCloud();
```

---

## 🛡️ Security Rules

### Firestore Security Rules
แทนที่ในหน้า **Firestore Database > Rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read all users (for chat/contacts)
    match /users/{userId} {
      allow read: if request.auth != null;
    }
    
    // Messages collection
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Storage Security Rules
แทนที่ในหน้า **Storage > Rules**:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /user_profiles/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 🔧 Troubleshooting

### ปัญหาที่พบบ่อย:

1. **Firebase not initialized**
   - ตรวจสอบว่า `FirebaseService.instance.initialize()` ถูกเรียกใน `main.dart`

2. **Permission denied**
   - ตรวจสอบ Security Rules ใน Firestore และ Storage

3. **Network connectivity**
   - ตรวจสอบว่า `connectivity_plus` package ทำงานถูกต้อง

4. **Web configuration**
   - ตรวจสอบ `web/index.html` มี Firebase config ถูกต้อง

### 📊 การตรวจสอบสถานะ:

```dart
// ตรวจสอบสถานะ Firebase
print('Firebase initialized: ${FirebaseService.instance.isInitialized}');
print('User synced: ${AuthService.instance.currentUser?.isSyncedToCloud}');
print('Firebase Auth: ${FirebaseAuth.instance.currentUser?.uid}');
```

---

## 🎯 ผลลัพธ์ที่คาดหวัง

เมื่อติดตั้งเสร็จแล้ว คุณจะสามารถ:

1. ✅ สร้าง user ออฟไลน์และ sync ขึ้น cloud เมื่อมีเน็ต
2. ✅ เห็นข้อมูล user ใน Firebase Console
3. ✅ รับ log messages ที่ชัดเจนเกี่ยวกับการ sync
4. ✅ ใช้งานแอปได้ทั้งออนไลน์และออฟไลน์

### 🔥 Log Messages ที่จะเห็น:
```
🔥 Firebase initialized successfully for web
🚀 Starting Firebase cloud sync for user: john@example.com
📤 User data uploaded to Firestore successfully!
🆔 Firebase UID: abc123def456
✅ User successfully synced to Firebase Cloud!
```

---

**หมายเหตุ**: อย่าลืมแทนที่ configuration values ด้วยค่าจริงจาก Firebase project ของคุณ!