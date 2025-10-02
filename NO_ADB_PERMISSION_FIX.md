# 🚨 **ADB NOT FOUND - Alternative Permission Fixes**

## 🔧 **Method 1: Manual Settings Fix (DO THIS FIRST)**

**On BOTH devices - EXACT STEPS:**

### **Device Settings:**
1. **Settings** → **Apps** → **Off-Grid SOS** (or your app name)
2. **Permissions** → **Location**
3. **CRITICAL**: Change from "Allow only while using the app" 
4. **TO**: "Allow all the time" ← **MUST BE THIS SETTING!**
5. **Also enable**: "Use precise location" if available

### **System Settings:**
1. **Settings** → **Location** → **ON**
2. **Settings** → **Location** → **Location Services** → **ON**
3. **Settings** → **Location** → **Google Location Accuracy** → **ON**

---

## 🔧 **Method 2: Setup ADB (Optional)**

If you want to use ADB commands:

### **Find Android SDK:**
```cmd
# Check if you have Android SDK installed:
dir "C:\Users\%USERNAME%\AppData\Local\Android\Sdk\platform-tools"
```

### **If SDK exists, add to PATH:**
```cmd
# Add this to your system PATH:
C:\Users\%USERNAME%\AppData\Local\Android\Sdk\platform-tools
```

### **Or use full path:**
```cmd
# Use full path instead of just 'adb':
"C:\Users\%USERNAME%\AppData\Local\Android\Sdk\platform-tools\adb.exe" devices
```

---

## 🔧 **Method 3: Flutter Commands (USE THIS)**

Instead of ADB, use Flutter's built-in debugging:

```cmd
# Connect device and check:
flutter devices

# Run with verbose logging:
flutter run --verbose

# Check app permissions via Flutter:
flutter logs | findstr -i permission
```

---

## 🔧 **Method 4: Developer Options Enable**

**On BOTH devices:**

1. **Settings** → **About Phone** → Tap **Build Number** 7 times
2. Go back to **Settings** → **Developer Options** (now visible)
3. **USB Debugging** → **ON**
4. **Stay Awake** → **ON**
5. **Mock Location Apps** → **None**

---

## 🎯 **MOST IMPORTANT: The Manual Settings Fix**

**The #1 thing you MUST do:**

### **Location Permission Level:**
- ❌ **"Deny"** 
- ❌ **"Allow only while using the app"** ← You probably have this
- ✅ **"Allow all the time"** ← You NEED this for P2P

**Why:** Nearby Connections works in background/when screen off, requiring "always" permission.

---

## 🧪 **Test After Settings Change:**

1. **Change location permission** to "Allow all the time" on BOTH devices
2. **Restart both devices** (important!)
3. **Test sequence:**
   ```
   Device A: Open app → SOS → Emergency → Should show "Broadcasting"
   Device B: Open app → Nearby Devices → Should find Device A
   ```

4. **Check logs:**
   ```cmd
   flutter logs
   ```

**SUCCESS = You'll see:**
```
✅ Permission.location อนุมัติแล้ว
🎯 พบอุปกรณ์: [device name]
```

**NO MORE:**
```
❌ MISSING_PERMISSION_ACCESS_COARSE_LOCATION
```

---

## 📱 **Visual Guide for Settings:**

### **Android 13/14:**
```
Settings → Apps → Off-Grid SOS → Permissions → Location
┌─────────────────────────────────┐
│ ○ Don't allow                   │
│ ○ Allow only while using the app│ ← Currently selected
│ ● Allow all the time            │ ← SELECT THIS!
└─────────────────────────────────┘
```

### **Also check:**
```
Settings → Location
┌─────────────────────────────────┐
│ Use location            [ON]    │
│ Google Location Accuracy [ON]   │
│ Location Services       [ON]    │
└─────────────────────────────────┘
```

---

## 🚨 **If Settings Don't Show "Allow all the time":**

Some Android versions hide this option. Try:

1. **Settings** → **Apps** → **Off-Grid SOS** → **Advanced** → **Background Activity** → **Allow**
2. **Settings** → **Battery** → **App battery usage** → **Off-Grid SOS** → **No restrictions**

---

**The manual settings change is your best bet! Focus on getting "Allow all the time" location permission on both devices.** 🎯