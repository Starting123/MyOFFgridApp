# 🚨 **IMMEDIATE FIX: P2P Discovery Not Working**

## 📱 **Quick Manual Steps (Do This Now)**

### **Step 1: Force Grant Permissions (Both Devices)**

Connect each device via USB and run these commands:

```bash
# Device 1 (connect and run):
adb devices
adb shell pm grant com.example.offgrid_sos_app android.permission.ACCESS_COARSE_LOCATION
adb shell pm grant com.example.offgrid_sos_app android.permission.ACCESS_FINE_LOCATION
adb shell pm grant com.example.offgrid_sos_app android.permission.BLUETOOTH_CONNECT
adb shell pm grant com.example.offgrid_sos_app android.permission.BLUETOOTH_ADVERTISE
adb shell pm grant com.example.offgrid_sos_app android.permission.BLUETOOTH_SCAN
adb shell pm grant com.example.offgrid_sos_app android.permission.NEARBY_WIFI_DEVICES

# Then switch USB to Device 2 and run the same commands
```

### **Step 2: Manual Settings Check (Both Devices)**

**On BOTH devices:**
1. Settings → Apps → Off-Grid SOS → Permissions
2. **Location**: Change to "Allow all the time" (NOT "Only while using app")
3. **Nearby devices**: Allow
4. **Device location**: Allow

**System Settings:**
1. Settings → Location → ON
2. Settings → Bluetooth → ON
3. Settings → WiFi → ON (doesn't need internet)

### **Step 3: Test Sequence (EXACT ORDER)**

**Device A (SOS Device):**
1. Force close app
2. Open app
3. Navigate to SOS screen
4. Tap "Emergency SOS"
5. Confirm → Should see "Broadcasting SOS..." or "Advertising..."
6. **WAIT 10 SECONDS** - don't touch anything

**Device B (Rescuer Device):**
1. Force close app
2. Open app
3. Navigate to "Nearby Devices" or "Discovery" screen
4. Should automatically start scanning
5. **Device A should appear in the list within 30 seconds**

### **Step 4: Check Logs (While Testing)**

Run this in terminal while testing:
```bash
flutter logs
```

**Look for these SUCCESS messages:**
```
✅ Permission.location อนุมัติแล้ว
✅ Nearby Service initialized สำเร็จ
📡 เริ่ม advertising: [device_name]
🔍 เริ่มสแกนหาอุปกรณ์ใกล้เคียง...
🎯 พบอุปกรณ์: [device_name]
```

**FAILURE messages to watch for:**
```
❌ Error discovering: MISSING_PERMISSION_ACCESS_COARSE_LOCATION
❌ Error advertising: [any error]
⚠️ Location permissions ไม่ครบถ้วน
```

---

## 🔧 **If Still Not Working**

### **Android Manifest Fix**

Check your `android/app/src/main/AndroidManifest.xml` has these permissions:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
```

### **Service ID Check**

Both devices MUST use the exact same service ID. Check both apps use:
`com.offgrid.sos`

### **Distance & Environment**
- Put devices within 2 meters
- Clear line of sight (no walls)
- Turn OFF mobile data and WiFi internet (keep WiFi on but disconnect from networks)
- Test in different location (some places have interference)

---

## 📞 **Emergency Debug Commands**

```bash
# Check current permissions:
adb shell dumpsys package com.example.offgrid_sos_app | findstr permission

# Clear app data and restart:
adb shell pm clear com.example.offgrid_sos_app

# Check Bluetooth status:
adb shell dumpsys bluetooth_manager

# Check WiFi status:  
adb shell dumpsys wifi
```

---

## 🎯 **Most Common Fix**

**90% of P2P discovery issues are fixed by:**

1. **Location permission**: Settings → Apps → Off-Grid SOS → Permissions → Location → "Allow all the time"
2. **Restart both devices** after changing permissions
3. **Use airplane mode with WiFi/Bluetooth on** (eliminates network interference)

Try this first before anything else!

---

## 📋 **Test Again After Fixes**

1. Follow Step 3 testing sequence exactly
2. Watch logs for success/error messages
3. If you see "พบอุปกรณ์" (device found) in logs = SUCCESS! 
4. If still not working, tell me the exact error messages from logs

The issue is almost certainly permissions - Android 13/14 are very strict about location permissions for P2P discovery.