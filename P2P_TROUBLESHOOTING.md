# 🔧 P2P Device Discovery Troubleshooting Guide

## 🚨 **ISSUE: Devices Not Seeing Each Other**

### 📋 **Quick Diagnosis Checklist**

**On BOTH devices, verify:**
- [ ] **Location Services**: Settings → Location → ON
- [ ] **Bluetooth**: Settings → Bluetooth → ON  
- [ ] **WiFi**: Settings → WiFi → ON (can be without internet)
- [ ] **App Permissions**: 
  - [ ] Location: Allow all the time
  - [ ] Nearby devices: Allow
  - [ ] Bluetooth: Allow
- [ ] **Developer Options**: Settings → Developer Options → Mock Location Apps: None

---

## 🔍 **Step-by-Step Fix Process**

### **STEP 1: Check App Logs**
When you run the app, look for these messages:

**✅ Good signs:**
```
✅ Permission.location อนุมัติแล้ว
✅ Permission.bluetoothConnect อนุมัติแล้ว  
✅ Nearby Service initialized สำเร็จ
📡 เริ่ม advertising: [device_name]
🔍 เริ่มสแกนหาอุปกรณ์ใกล้เคียง...
```

**❌ Bad signs:**
```
❌ Error discovering: MISSING_PERMISSION_ACCESS_COARSE_LOCATION
❌ Error advertising: [any error]
🔄 กำลังขอ permissions... (stuck here)
```

### **STEP 2: Fix Permission Issues**

If you see permission errors:

1. **Force-grant permissions manually:**
   ```bash
   # Connect device via USB debugging
   adb shell pm grant com.example.offgrid_sos_app android.permission.ACCESS_COARSE_LOCATION
   adb shell pm grant com.example.offgrid_sos_app android.permission.ACCESS_FINE_LOCATION
   adb shell pm grant com.example.offgrid_sos_app android.permission.BLUETOOTH_CONNECT
   adb shell pm grant com.example.offgrid_sos_app android.permission.BLUETOOTH_ADVERTISE
   adb shell pm grant com.example.offgrid_sos_app android.permission.BLUETOOTH_SCAN
   adb shell pm grant com.example.offgrid_sos_app android.permission.NEARBY_WIFI_DEVICES
   ```

2. **Or manually in device settings:**
   - Settings → Apps → Off-Grid SOS → Permissions
   - Enable ALL permissions (especially Location "All the time")

### **STEP 3: Test Discovery Protocol**

**Device A (SOS Mode):**
1. Open app
2. Go to SOS screen
3. Tap "Emergency SOS" 
4. Confirm → Should start advertising
5. Look for log: `📡 เริ่ม advertising: [name]`

**Device B (Rescuer Mode):**
1. Open app  
2. Go to "Nearby Devices" or Discovery screen
3. Should start scanning automatically
4. Look for log: `🔍 เริ่มสแกนหาอุปกรณ์ใกล้เคียง...`
5. Device A should appear in the list

### **STEP 4: Android Version Compatibility**

Your devices:
- Device A: Android 14 (API 34)
- Device B: Android 13 (API 33)

**Known issues:**
- Android 13+ requires `NEARBY_WIFI_DEVICES` permission
- Android 14 has stricter location requirements

---

## 🛠️ **Code Fixes Needed**

Let me check and fix potential issues in the code:

### **Issue 1: Permission Handling**

The app might not be requesting all required permissions properly.

### **Issue 2: Service ID Mismatch**

Both devices must use the exact same service ID for discovery.

### **Issue 3: Strategy Configuration**

The P2P strategy might not be optimal for your use case.

---

## 🧪 **Testing Commands**

### **Check Current Permissions:**
```bash
# Check what permissions the app has
adb shell dumpsys package com.example.offgrid_sos_app | findstr permission
```

### **View Real-time Logs:**
```bash
# See detailed logs from both devices
flutter logs
```

### **Force Clean Start:**
```bash
# Clear app data and restart
adb shell pm clear com.example.offgrid_sos_app
flutter run --debug
```

---

## 🎯 **Quick Fix Solutions**

### **Solution 1: Enable Developer Options**
1. Settings → About Phone → Tap "Build Number" 7 times
2. Settings → Developer Options → ON
3. USB Debugging → ON
4. Stay Awake → ON

### **Solution 2: Network Reset**
1. Turn OFF WiFi and Mobile Data
2. Turn ON Bluetooth
3. Test P2P discovery (should work offline)

### **Solution 3: Distance Test**
1. Put devices within 1 meter of each other
2. Clear line of sight (no walls/obstacles)
3. Test discovery again

---

## 📱 **Manual Testing Steps**

1. **Reset both apps:**
   - Force close apps
   - Clear app cache
   - Restart both devices

2. **Test sequence:**
   ```
   Device A: Open app → SOS → Start Emergency
   Wait 5 seconds
   Device B: Open app → Nearby Devices → Should see Device A
   ```

3. **Check logs on both devices simultaneously**

---

## 🔧 **If Still Not Working**

Let me know:
1. What error messages you see in the logs
2. Which permissions are granted/denied
3. What happens when you try discovery

I'll then provide specific code fixes for your exact issue.

The most common fix is usually the location permission - it needs to be "Allow all the time" not just "Allow while using app".