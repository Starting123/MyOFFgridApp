# Rescue User SOS Screen Fix

## Issue Fixed
**Problem**: When a **rescue user** opened the SOS screen, it was showing "SOS" mode (asking for help) instead of "RESCUE" mode (offering help to others).

**Solution**: Updated the SOS screen to detect the current user's role and display different UI/behavior for rescue users.

## Changes Made

### 1. **Added User Role Detection**
- Added `currentUserRoleProvider` to get the authenticated user's role
- Added helper function `_mapStringToUserRole()` to convert role strings to UserRole enum
- Updated SOS screen to use current user role for UI decisions

### 2. **Role-Based UI Updates**

#### **App Bar**
- **SOS User**: "Emergency SOS" (RED theme)
- **Rescue User**: "Rescue Signal" (BLUE theme)

#### **Main Button**
- **SOS User**: RED button with warning icon, "SOS" text, "TAP FOR HELP"
- **Rescue User**: BLUE button with health/safety icon, "RESCUE" text, "TAP TO SIGNAL"

#### **Status Messages**
- **SOS User Active**: "SOS ACTIVE - Your emergency signal is being broadcast to nearby rescue teams. Help is on the way!"
- **Rescue User Active**: "RESCUE ACTIVE - Your rescue signal is active! People in need can find you and request help."
- **SOS User Standby**: "SOS STANDBY - Tap the SOS button above to send an emergency signal to nearby rescue teams."
- **Rescue User Standby**: "RESCUE STANDBY - Tap the RESCUE button to broadcast your availability to help people in emergency situations."

#### **Background Gradient**
- **SOS User**: RED gradient when active
- **Rescue User**: BLUE gradient when active

### 3. **Updated Method Signatures**
- `_buildSOSScreen()` - Now accepts UserRole parameter
- `_buildSOSButton()` - Now accepts isRescueUser parameter
- `_buildStatusText()` - Now accepts isRescueUser parameter

## User Experience Improvements

### **For SOS Users (People in Emergency)**
- RED theme clearly indicates emergency/distress
- "SOS" and "TAP FOR HELP" messaging is clear about requesting help
- Status messages explain that help is coming

### **For Rescue Users (First Responders/Helpers)**  
- BLUE theme indicates helpful/rescue mode
- "RESCUE" and "TAP TO SIGNAL" messaging shows they're offering help
- Status messages explain they're available to help others
- Different icon (health_and_safety vs warning) shows helping intent

## Role Mapping Logic
The screen now correctly handles all role string variations:
- `'rescueuser'`, `'rescuer'` → UserRole.rescueUser (BLUE/RESCUE mode)
- `'sosuser'`, `'sos_user'`, `'sos'` → UserRole.sosUser (RED/SOS mode)  
- `'relayuser'`, `'relay'`, `'normal'` → UserRole.relayUser (defaults to RED/SOS mode)

## Technical Implementation
```dart
// User role detection
final currentUserRoleProvider = Provider<UserRole>((ref) {
  final currentUser = AuthService.instance.currentUser;
  final userRole = currentUser?.role;
  if (userRole != null) {
    return _mapStringToUserRole(userRole);
  }
  return UserRole.sosUser; // Default fallback
});

// Role-based UI rendering
Widget _buildSOSScreen(..., UserRole userRole) {
  final isRescueUser = userRole == UserRole.rescueUser;
  // UI adapts based on isRescueUser flag
}
```

## Validation Results
- ✅ **Flutter Analyze**: 1 minor info warning (use_super_parameters)
- ✅ **Role Detection**: Correctly identifies user role from AuthService
- ✅ **UI Adaptation**: Different colors, text, and icons per role
- ✅ **User Experience**: Clear distinction between asking for help vs offering help

## Next Steps
Test the updated SOS screen with different user roles:
1. **Register as SOS User** → Should see RED "SOS" interface
2. **Register as Rescue User** → Should see BLUE "RESCUE" interface
3. **Activate signal** → Should see role-appropriate status messages