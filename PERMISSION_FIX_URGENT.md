# 🚨 **CONFIRMED ISSUE: MISSING_PERMISSION_ACCESS_COARSE_LOCATION**

## 📱 **The Problem is Clear:**
Your terminal shows: `MISSING_PERMISSION_ACCESS_COARSE_LOCATION`

This means the location permission is **NOT PROPERLY GRANTED** despite what you might see in app settings.

## 🔧 **IMMEDIATE FIX - Do This Now:**

### **Method 1: ADB Force Grant (RECOMMENDED)**

Connect each device via USB and run:

```bash
# For Device 1:
adb devices
adb shell pm grant com.example.offgrid_sos_app android.permission.ACCESS_COARSE_LOCATION
adb shell pm grant com.example.offgrid_sos_app android.permission.ACCESS_FINE_LOCATION

# Switch USB cable to Device 2 and repeat:
adb shell pm grant com.example.offgrid_sos_app android.permission.ACCESS_COARSE_LOCATION  
adb shell pm grant com.example.offgrid_sos_app android.permission.ACCESS_FINE_LOCATION
```

### **Method 2: Manual Settings Fix (CRITICAL)**

**On BOTH devices - EXACT STEPS:**

1. **Settings** → **Apps** → **Off-Grid SOS** 
2. **Permissions** → **Location**
3. **CHANGE FROM**: "Allow only while using the app"
4. **CHANGE TO**: "Allow all the time" ← **THIS IS THE KEY!**
5. **Also enable**: "Use precise location"

### **Method 3: Developer Options Fix**

**On BOTH devices:**
1. **Settings** → **About Phone** → Tap **Build Number** 7 times
2. **Settings** → **Developer Options** 
3. **Mock Location Apps** → Set to **"None"**
4. **Stay Awake** → **ON**

## 🔄 **After Fixing Permissions:**

### **Test Sequence:**
1. **Force close** both apps
2. **Restart** both devices (important!)
3. **Device A**: Open app → SOS → Emergency SOS → Confirm
4. **Device B**: Open app → Nearby Devices → Should see Device A

### **Check Logs Again:**
```bash
flutter logs
```

**SUCCESS = You should see:**
```
✅ Permission.location อนุมัติแล้ว
✅ Nearby Service initialized สำเร็จ  
📡 เริ่ม advertising: [device]
🔍 เริ่มสแกนหาอุปกรณ์ใกล้เคียง...
🎯 พบอุปกรณ์: [device name]
```

**NO MORE:**
```
❌ Error discovering: MISSING_PERMISSION_ACCESS_COARSE_LOCATION
```

---

## 🛠️ **If ADB Method Doesn't Work:**

### **Reset App Permissions Completely:**
```bash
adb shell pm reset-permissions com.example.offgrid_sos_app
adb shell pm clear com.example.offgrid_sos_app
```

Then reinstall:
```bash
flutter clean
flutter run
```

---

## 🎯 **Root Cause Analysis:**

Android 13/14 have **3 levels** of location permission:
1. **Denied** 
2. **Allow while using app** ← **This is what you currently have**
3. **Allow all the time** ← **This is what you NEED for P2P**

**Nearby Connections requires "Allow all the time" because it works in background/when screen is off.**

---

## 📞 **Quick Verification:**

After fixing permissions, run this to verify:
```bash
adb shell dumpsys package com.example.offgrid_sos_app | findstr -i location
```

Should show:
```
android.permission.ACCESS_COARSE_LOCATION: granted=true
android.permission.ACCESS_FINE_LOCATION: granted=true
```

**The location permission "Allow all the time" setting is definitely your issue! Fix this and P2P discovery will work.** 🚀