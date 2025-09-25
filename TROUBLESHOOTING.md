# การแก้ปัญหาการเชื่อมต่อ SOS และ Rescuer

## ปัญหาที่พบบ่อย: เครื่องหาเครื่องอื่นไม่เจอ

### วิธีตรวจสอบและแก้ไข

#### 1. ตรวจสอบ Permissions
```bash
# เปิด Settings > Apps > Off-Grid SOS > Permissions
- Location: "Allow all the time" ✅
- Bluetooth: "Allow" ✅
- Nearby devices: "Allow" ✅
- Camera: "Allow" ✅
- Storage: "Allow" ✅
```

#### 2. ตรวจสอบการตั้งค่าระบบ
```
Android Settings:
- Bluetooth: เปิด ✅
- Location/GPS: เปิด ✅
- WiFi: เปิด (หรือปิดสำหรับทดสอบ offline) 
- Mobile Data: ปิด (สำหรับทดสอบ offline)
```

#### 3. ขั้นตอนการทดสอบที่ถูกต้อง

**เครื่องที่ 1 (SOS Device):**
```
1. เปิดแอป
2. ไปที่ Settings > กรอกชื่อ "SOS_Device_1"
3. เลือก Device Type: "🆘 SOS - ผู้ประสบภัย"
4. บันทึก
5. กลับหน้าหลัก
6. กด SOS button (ปุ่มสีแดง)
7. รอ 10 วินาที ให้ระบบ advertising
```

**เครื่องที่ 2 (Rescuer Device):**
```
1. เปิดแอป
2. ไปที่ Settings > กรอกชื่อ "Rescuer_1"
3. เลือก Device Type: "👨‍⚕️ Rescuer - นักกู้ภัย"
4. บันทึก
5. กลับหน้าหลัก
6. เปิด Rescuer Mode (สวิตช์สีน้ำเงิน)
7. กด Device List button (ไอคอน devices)
8. กด Scan button (ปุ่มสีน้ำเงิน)
9. รอ 30 วินาที
```

#### 4. ตรวจสอบ Debug Logs

**ใน Android Studio/VS Code Debug Console ควรเห็น:**

**SOS Device:**
```
🆘 เปิด SOS Mode...
🔄 เริ่มต้น services...
P2P Service: ✅
Nearby Service: ✅
📡 เริ่ม advertising...
✅ เริ่ม advertising สำเร็จ: SOS_Device_1
```

**Rescuer Device:**
```
👨‍⚕️ เปิด Rescuer Mode...
🔍 เริ่มสแกนหา SOS signals...
✅ เริ่มสแกนสำเร็จ
🎯 พบอุปกรณ์: endpoint_123
   Name: SOS_Device_1
🤝 มีการเชื่อมต่อเข้ามา: endpoint_123
✅ เชื่อมต่อสำเร็จ: endpoint_123
```

#### 5. ถ้ายังไม่เจอ ให้ลองขั้นตอนนี้:

**Reset การเชื่อมต่อ:**
```
1. ปิดแอปทั้งสองเครื่อง (force close)
2. เปิด Settings > Apps > Off-Grid SOS > Storage > Clear Data
3. รีสตาร์ทอุปกรณ์ทั้งสอง
4. เปิด Bluetooth และ Location ใหม่
5. เปิดแอปและทำขั้นตอนใหม่
```

**ทดสอบระยะทาง:**
```
1. วางอุปกรณ์ห่างกัน 2-3 เมตร
2. ถ้าไม่เจอ ให้เข้าใกล้กันมากขึ้น (1 เมตร)
3. ห้ามมีสิ่งกีดขวางระหว่างอุปกรณ์
```

#### 6. วิธีตรวจสอบว่า Services ทำงาน

**ใน Device List Screen:**
```
- ถ้าเห็น "กำลังเริ่มต้นระบบ P2P และ Bluetooth..." = กำลังทำงาน ✅
- ถ้าเห็น "ไม่พบอุปกรณ์ใกล้เคียง" หลังจาก 30 วินาที = มีปัญหา ❌
```

#### 7. ปัญหาเฉพาะ Android

**Android 12+ (API 31+):**
```
- ต้องมี BLUETOOTH_SCAN permission
- ต้องมี BLUETOOTH_ADVERTISE permission  
- ต้องมี NEARBY_WIFI_DEVICES permission
```

**Android 13+ (API 33+):**
```
- Permission ใหม่: NEARBY_WIFI_DEVICES
- อาจต้องอนุมัติใน Settings manually
```

#### 8. คำแนะนำเพิ่มเติม

**การทดสอบแบบ Step-by-step:**
```
1. ทดสอบ 1 เครื่องเป็น SOS ก่อน (ดู logs)
2. ทดสอบ 1 เครื่องเป็น Rescuer ก่อน (ดู logs)
3. ทดสอบทั้งสองเครื่องพร้อมกัน
```

**หากยังไม่ได้ผล:**
```
1. ลองใช้ emulator + real device
2. ลองใช้ 2 real devices ยี่ห้อเดียวกัน
3. ตรวจสอบ Android version compatibility
```

## ข้อมูล Technical

**Nearby Connections API ใช้:**
- WiFi Direct (primary)
- Bluetooth LE (fallback)
- P2P_CLUSTER strategy

**ระยะการทำงาน:**
- WiFi Direct: ~100 เมตร
- Bluetooth LE: ~10 เมตร

**เวลาที่ใช้:**
- Discovery: 10-30 วินาที
- Connection: 5-10 วินาที
- Message transfer: 1-3 วินาที