# 🎯 คู่มือการทดสอบ MyOFFgridApp หลังการแก้ไข

## ✅ การแก้ไขที่ทำไปแล้ว

### 1. แก้ไขปัญหา STATUS_ALREADY_ADVERTISING/STATUS_ALREADY_DISCOVERING
- **ปัญหา**: แอปขึ้น error เมื่อเปิด/ปิด SOS หรือ Rescuer mode หลายครั้ง
- **การแก้ไข**: เปลี่ยนจาก retry logic เป็นการ ignore error และให้ service ทำงานต่อ
- **ผลลัพธ์**: แอปจะแสดง "ℹ️ Service กำลัง advertising/discovering อยู่แล้ว - ใช้งานได้ปกติ"

### 2. แก้ไขปัญหา UI setState Error
- **ปัญหา**: Error เมื่อออกจากหน้าสแกนอุปกรณ์
- **การแก้ไข**: เพิ่มการตรวจสอบ `mounted` ก่อนเรียก setState
- **ผลลัพธ์**: ไม่มี crash เมื่อออกจากหน้าจอ

## 🧪 วิธีการทดสอบ

### ขั้นตอนที่ 1: Build และ Install
```bash
# Build APK
flutter build apk --debug

# Install บนอุปกรณ์ทั้ง 2 เครื่อง
flutter install -d [device_id_1]
flutter install -d [device_id_2]
```

### ขั้นตอนที่ 2: เตรียมอุปกรณ์
1. **เปิด WiFi และ Bluetooth** บนอุปกรณ์ทั้ง 2 เครื่อง
2. **วางอุปกรณ์ใกล้กัน** (ระยะไม่เกิน 10 เมตร)
3. **เปิดแอป** บนอุปกรณ์ทั้ง 2 เครื่อง

### ขั้นตอนที่ 3: ทดสอบการค้นหาอุปกรณ์
1. **อุปกรณ์เครื่องที่ 1**: กด "เปิด SOS"
2. **อุปกรณ์เครื่องที่ 2**: กด "เปิด Rescuer"
3. **ทั้ง 2 เครื่อง**: กด "สแกนอุปกรณ์"

### ขั้นตอนที่ 4: ตรวจสอบผลลัพธ์

#### ✅ สิ่งที่ควรเห็น:
- ใน flutter logs: "พบอุปกรณ์: [endpoint_id]"
- ใน flutter logs: "เชื่อมต่อสำเร็จ: [endpoint_id]"
- ใน flutter logs: "Total connections: 1"
- ในหน้าสแกน: ชื่ออุปกรณ์ปรากฏในรายการ

#### ⚠️ ข้อความที่อาจเห็น (ปกติ):
- "ℹ️ Service กำลัง advertising อยู่แล้ว - ใช้งานได้ปกติ"
- "ℹ️ Service กำลัง discovering อยู่แล้ว - ใช้งานได้ปกติ"
- "P2P Service: ❌" (ไม่ส่งผลต่อการทำงาน)

## 🔧 การตรวจสอบ Logs

### เพื่อดู logs แบบ real-time:
```bash
flutter logs
```

### Logs สำคัญที่ต้องดู:
```
I/flutter: 🎯 พบอุปกรณ์: [ID]
I/flutter: 🤝 มีการเชื่อมต่อเข้ามา: [ID]
I/flutter: ✅ เชื่อมต่อสำเร็จ: [ID]
I/flutter: Total connections: 1
```

## 🎉 ผลการทดสอบที่คาดหวัง

จากการทดสอบเมื่อกี้ พบว่า:
- ✅ **แอป build สำเร็จ**
- ✅ **อุปกรณ์สามารถค้นพบกันได้** ("พบอุปกรณ์: EXBS")
- ✅ **การเชื่อมต่อทำงานได้** ("เชื่อมต่อสำเร็จ", "Total connections: 1")
- ✅ **ไม่มี crash เมื่อเปิด/ปิด modes หลายครั้ง**

## 🚨 หากยังมีปัญหา

1. **รีสตาร์ทอุปกรณ์ทั้ง 2 เครื่อง**
2. **ตรวจสอบ permissions** ในการตั้งค่าของแอป
3. **ลองปิดแอปอื่นๆ ที่ใช้ Bluetooth/WiFi**
4. **ใช้คำสั่ง**: `flutter clean && flutter build apk --debug`

---
*อัปเดตล่าสุด: หลังจากแก้ไข error handling และ UI state management*