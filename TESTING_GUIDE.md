# Off-Grid SOS App - Complete Testing Guide# 🎯 คู่มือการทดสอบ MyOFFgridApp หลังการแก้ไข



## 🚀 **Quick Start - 2 Device Testing**## ✅ การแก้ไขที่ทำไปแล้ว



### Prerequisites### 1. แก้ไขปัญหา STATUS_ALREADY_ADVERTISING/STATUS_ALREADY_DISCOVERING

- 2 Android devices (minimum Android 6.0)- **ปัญหา**: แอปขึ้น error เมื่อเปิด/ปิด SOS หรือ Rescuer mode หลายครั้ง

- APK build of the app installed on both devices- **การแก้ไข**: เปลี่ยนจาก retry logic เป็นการ ignore error และให้ service ทำงานต่อ

- Physical proximity (within 10 meters recommended)- **ผลลัพธ์**: แอปจะแสดง "ℹ️ Service กำลัง advertising/discovering อยู่แล้ว - ใช้งานได้ปกติ"



### Test Environment Setup### 2. แก้ไขปัญหา UI setState Error

- **ปัญหา**: Error เมื่อออกจากหน้าสแกนอุปกรณ์

#### **Device Configuration**- **การแก้ไข**: เพิ่มการตรวจสอบ `mounted` ก่อนเรียก setState

1. **Enable Developer Options** on both devices:- **ผลลัพธ์**: ไม่มี crash เมื่อออกจากหน้าจอ

   - Go to Settings → About Phone

   - Tap "Build Number" 7 times## 🧪 วิธีการทดสอบ

   - Go to Settings → Developer Options

   - Enable "Stay Awake" (keeps screen on while charging)### ขั้นตอนที่ 1: Build และ Install

```bash

2. **Network Setup**:# Build APK

   - Turn ON WiFi on both devicesflutter build apk --debug

   - Turn ON Bluetooth on both devices

   - Turn ON Location Services with High Accuracy# Install บนอุปกรณ์ทั้ง 2 เครื่อง

   - **Keep Mobile Data ON** (for initial setup, can disable later for true offline test)flutter install -d [device_id_1]

flutter install -d [device_id_2]

3. **App Permissions**:```

   - Install APK and grant ALL permissions when prompted

   - If permissions are denied, go to Settings → Apps → OffGrid SOS → Permissions and enable all### ขั้นตอนที่ 2: เตรียมอุปกรณ์

1. **เปิด WiFi และ Bluetooth** บนอุปกรณ์ทั้ง 2 เครื่อง

---2. **วางอุปกรณ์ใกล้กัน** (ระยะไม่เกิน 10 เมตร)

3. **เปิดแอป** บนอุปกรณ์ทั้ง 2 เครื่อง

## 🔧 **Core Functionality Testing**

### ขั้นตอนที่ 3: ทดสอบการค้นหาอุปกรณ์

### **Test 1: App Initialization and Permissions**1. **อุปกรณ์เครื่องที่ 1**: กด "เปิด SOS"

2. **อุปกรณ์เครื่องที่ 2**: กด "เปิด Rescuer"

**Device A (SOS Victim):**3. **ทั้ง 2 เครื่อง**: กด "สแกนอุปกรณ์"

```

1. Open OffGrid SOS app### ขั้นตอนที่ 4: ตรวจสอบผลลัพธ์

2. Grant all permissions (Location, Bluetooth, WiFi, Camera, etc.)

3. Check logs for permission status#### ✅ สิ่งที่ควรเห็น:

4. Verify "Permission Summary" shows ✅ for essential permissions- ใน flutter logs: "พบอุปกรณ์: [endpoint_id]"

```- ใน flutter logs: "เชื่อมต่อสำเร็จ: [endpoint_id]"

- ใน flutter logs: "Total connections: 1"

**Device B (Rescuer):**- ในหน้าสแกน: ชื่ออุปกรณ์ปรากฏในรายการ

```

1. Open OffGrid SOS app #### ⚠️ ข้อความที่อาจเห็น (ปกติ):

2. Grant all permissions- "ℹ️ Service กำลัง advertising อยู่แล้ว - ใช้งานได้ปกติ"

3. Verify same permission summary- "ℹ️ Service กำลัง discovering อยู่แล้ว - ใช้งานได้ปกติ"

```- "P2P Service: ❌" (ไม่ส่งผลต่อการทำงาน)



**Expected Results:**## 🔧 การตรวจสอบ Logs

- Both apps launch successfully

- No crash on startup### เพื่อดู logs แบบ real-time:

- Permission summary shows at least Location, Bluetooth Connect/Scan as granted```bash

flutter logs

### **Test 2: SOS Broadcasting**```



**Device A (Victim) Steps:**### Logs สำคัญที่ต้องดู:

``````

1. Go to SOS tab in appI/flutter: 🎯 พบอุปกรณ์: [ID]

2. Select "SOS Mode" (Red button)I/flutter: 🤝 มีการเชื่อมต่อเข้ามา: [ID]

3. Enter emergency message: "TEST SOS - Simulated Emergency"I/flutter: ✅ เชื่อมต่อสำเร็จ: [ID]

4. Tap "ACTIVATE SOS" buttonI/flutter: Total connections: 1

5. Watch for red pulsing animation```

6. Check device discovery starts automatically

```## 🎉 ผลการทดสอบที่คาดหวัง



**Device B (Rescuer) Steps:**จากการทดสอบเมื่อกี้ พบว่า:

```- ✅ **แอป build สำเร็จ**

1. Go to SOS tab- ✅ **อุปกรณ์สามารถค้นพบกันได้** ("พบอุปกรณ์: EXBS")

2. Select "Rescuer Mode" (Blue button) - ✅ **การเชื่อมต่อทำงานได้** ("เชื่อมต่อสำเร็จ", "Total connections: 1")

3. Tap "START LISTENING FOR SOS"- ✅ **ไม่มี crash เมื่อเปิด/ปิด modes หลายครั้ง**

4. Go to Devices tab

5. Tap "DISCOVER DEVICES"## 🚨 หากยังมีปัญหา

```

1. **รีสตาร์ทอุปกรณ์ทั้ง 2 เครื่อง**

**Expected Results:**2. **ตรวจสอบ permissions** ในการตั้งค่าของแอป

- Device A shows "SOS ACTIVE" with red pulsing animation3. **ลองปิดแอปอื่นๆ ที่ใช้ Bluetooth/WiFi**

- Device A starts advertising as "SOS_EMERGENCY"4. **ใช้คำสั่ง**: `flutter clean && flutter build apk --debug`

- Device B finds Device A in nearby devices list

- Device B receives SOS notification with emergency message---

*อัปเดตล่าสุด: หลังจากแก้ไข error handling และ UI state management*
### **Test 3: Device Discovery and Connection**

**Both Devices:**
```
1. Go to Devices tab
2. Tap "DISCOVER DEVICES" 
3. Wait 10-30 seconds for discovery
4. Check nearby devices list populates
```

**Device B (Rescuer):**
```
1. Find Device A in devices list (should show as SOS active)
2. Tap on Device A entry
3. Tap "CONNECT"
4. Wait for connection confirmation
```

**Expected Results:**
- Both devices appear in each other's "Nearby Devices" list
- Device A shows as "SOS Active" in Device B's list
- Connection succeeds and shows "Connected" status
- Green connection indicator appears

### **Test 4: Messaging Between Connected Devices**

**Device A (SOS Victim):**
```
1. Go to Chat tab
2. Select Device B from chat list
3. Type: "SOS: I'm trapped in building, need help urgently!"
4. Send message
5. Send location by tapping location button
```

**Device B (Rescuer):**
```
1. Go to Chat tab  
2. Should see new conversation with Device A
3. Open chat with Device A
4. Verify SOS message received
5. Reply: "Help is on the way! Share your exact location"
6. Check if location message received
```

**Expected Results:**
- Messages appear in real-time between devices
- SOS messages show with red emergency styling
- Location messages display with coordinates
- Message status shows "Delivered" when received

---

## 🔄 **Offline Mode Testing**

### **Test 5: Full Offline Operation**

**Both Devices:**
```
1. Turn OFF Mobile Data completely
2. Turn OFF WiFi Internet (keep WiFi Direct on)
3. Keep Bluetooth ON
4. Keep Location Services ON
5. Restart the app
```

**Repeat Tests 2-4 in Full Offline Mode:**
- SOS Broadcasting should still work
- Device discovery via Bluetooth/WiFi Direct
- Messaging should continue working
- All data stored locally in database

**Expected Results:**
- App works completely offline
- All core functionality preserved
- Messages queued for cloud sync when internet restored

---

## 📊 **Advanced Testing Scenarios**

### **Test 6: Multi-Device Mesh Network**

**If you have 3+ devices:**
```
Device A: SOS Victim
Device B: First Rescuer  
Device C: Second Rescuer/Relay

1. Device A broadcasts SOS
2. Devices B & C both enter Rescuer mode
3. All devices discover each other
4. Test message relay: A → B → C
5. Verify all devices receive SOS broadcast
```

### **Test 7: Connection Recovery**

**Simulate Connection Loss:**
```
1. Connect Device A and B successfully
2. Move devices far apart (or disable Bluetooth on one)
3. Verify connection loss detected
4. Bring devices back together
5. Check automatic reconnection
6. Verify message sync after reconnection
```

### **Test 8: Database and Cloud Sync**

**Test Local Storage:**
```
1. Send multiple messages while connected
2. Close app on both devices
3. Reopen app - verify messages persist
4. Check emergency messages stored properly
```

**Test Cloud Sync (when internet restored):**
```
1. Complete offline messaging session
2. Turn Mobile Data back ON
3. Messages should sync to cloud automatically
4. Check sync status indicators
```

---

## 🐛 **Troubleshooting Common Issues**

### **Discovery Fails**
```
Problem: Devices don't find each other
Solutions:
- Ensure both devices have Location ON (critical!)
- Check Bluetooth permissions granted
- Restart discovery on both devices
- Move devices closer (<5 meters)
- Restart app if needed
```

### **Connection Fails**
```
Problem: Devices found but won't connect
Solutions:
- Grant all Bluetooth permissions
- Clear Bluetooth cache in Android settings
- Ensure devices aren't connected to other Bluetooth devices
- Restart Bluetooth on both devices
```

### **Messages Not Sending**
```
Problem: Messages show "Sending" but never delivered
Solutions:
- Verify devices are connected (green indicator)
- Check message queue in Chat settings
- Restart connection
- Check database for pending messages
```

### **SOS Not Broadcasting**
```
Problem: SOS activation doesn't broadcast
Solutions:
- Verify location permissions granted
- Check advertising service started
- Ensure Nearby Connections initialized
- Check service logs for errors
```

---

## 📱 **Testing Checklist**

### **Basic Functionality** ✅
- [ ] App launches without crashes
- [ ] All permissions granted
- [ ] SOS mode activation works
- [ ] Rescuer mode activation works
- [ ] Device discovery finds nearby devices
- [ ] Connection establishment succeeds
- [ ] Text messaging works bidirectionally
- [ ] Location sharing works
- [ ] Emergency message broadcasting
- [ ] App works in airplane mode (WiFi/Bluetooth only)

### **Advanced Features** ✅
- [ ] Background SOS broadcasting
- [ ] Multi-device mesh networking
- [ ] Connection recovery after loss
- [ ] Message persistence in database
- [ ] Cloud sync when internet restored
- [ ] File/image sharing (if implemented)
- [ ] Battery optimization handling
- [ ] Performance under low connectivity

### **Edge Cases** ✅
- [ ] App behavior with low battery
- [ ] Connection handling with weak signal
- [ ] Large message handling
- [ ] Multiple SOS sources simultaneously
- [ ] App termination and recovery
- [ ] Permission revocation handling

---

## 🔍 **Debugging Tools**

### **Check App Logs**
```bash
# Connect device to computer and use ADB
adb logcat | grep -E "(🚨|✅|❌|🔍|📡)"

# Or use Android Studio Device Monitor
# Filter by "OffGrid" or "SOS" tags
```

### **Monitor Database**
```
- Use debugging screens in app (if available)
- Check message queue status
- Verify device discovery logs
- Monitor connection state changes
```

### **Network Monitoring**
```
- Android Settings → Developer Options → Bluetooth HCI snoop log
- WiFi Direct connection logs
- Nearby Connections API status
```

---

## 🎯 **Success Criteria**

### **Minimum Viable Test (2 devices, 15 minutes)**
1. ✅ Both devices launch and get permissions
2. ✅ Device A broadcasts SOS successfully  
3. ✅ Device B discovers Device A as SOS source
4. ✅ Devices connect to each other
5. ✅ Emergency message exchanged successfully
6. ✅ Location shared between devices
7. ✅ All functionality works offline (no internet)

### **Full Test Suite (2+ devices, 45 minutes)**
- All basic functionality tests pass
- Advanced scenarios work correctly
- Edge cases handled gracefully
- Performance remains stable
- Data persistence verified
- Cloud sync functional

---

## 📞 **Emergency Simulation Scripts**

### **Scenario 1: Lost Hiker**
```
Device A (Hiker): "SOS: Lost on mountain trail, injured ankle, low battery. GPS coordinates needed urgently!"
Device B (Rescuer): "Rescue team notified. Share exact location. Conserve battery. Help coming."
```

### **Scenario 2: Natural Disaster**
```
Device A (Victim): "SOS: Earthquake trapped in building collapse. Multiple injuries. Need rescue team!"
Device B (Coordinator): "Emergency response dispatched. How many people? Any medical emergencies?"
```

### **Scenario 3: Remote Area Emergency**
```
Device A (Emergency): "SOS: Vehicle breakdown in remote area. No cell service. Need tow truck."
Device B (Helper): "Location received. Contacting local services. Stay with vehicle."
```

---

This testing guide ensures comprehensive validation of all core Off-Grid SOS functionality. Start with basic 2-device testing, then expand to advanced scenarios as the app proves stable.