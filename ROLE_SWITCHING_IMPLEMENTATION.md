# Role Switching Implementation - Testing Guide

## Overview
This document outlines the complete role switching implementation and provides a testing guide to verify the functionality.

## Implementation Summary

### ✅ Completed Features

#### 1. **Settings UI Enhancement**
- Added role switching section in Settings screen
- Interactive role selection with visual role cards
- Current role display with color-coded indicators
- Confirmation dialog with role change warnings

#### 2. **AuthService Enhancement**
- Added `updateRole(String newRole)` method
- Offline-first role storage in SQLite and SharedPreferences  
- Real-time user stream updates when role changes
- Integration with ServiceCoordinator for device re-registration

#### 3. **Provider Integration**
- Updated all `_mapStringToUserRole` functions to handle new role formats
- Reactive UI updates via existing `userStream` from AuthService
- Consistent role mapping across home, settings, and SOS screens

#### 4. **ServiceCoordinator Integration**
- Added `updateDeviceRole(String newRole)` method
- Re-registers device with new role across all services
- Updates device advertising name to include role
- Propagates role changes to Nearby, P2P, BLE, and Mesh services

#### 5. **Real Auth Check**
- Fixed main app auth check to use real `AuthService.isLoggedIn`
- Proper authentication flow on app startup

## Testing Flow

### Test 1: Basic Role Switching
1. **Start App** → Register as "SOS User" (RED theme)
2. **Navigate** → Settings screen
3. **Verify** → Current role shows as "SOS User" with red badge
4. **Tap** → "Change Role" button
5. **Select** → "Rescue User" from dialog
6. **Confirm** → Role switch confirmation
7. **Verify** → Success message shows "Role switched to Rescue User"
8. **Check** → Settings screen updates to show blue "Rescue User" badge
9. **Navigate** → Home screen → Verify blue theme
10. **Navigate** → SOS screen → Verify "RESCUE" button (blue theme)

### Test 2: Role Persistence
1. **Complete Test 1** (switch to Rescue User)
2. **Force close** app completely
3. **Restart** app
4. **Verify** → App opens to main screen (not registration)
5. **Check** → Home screen shows blue theme (Rescue User)
6. **Check** → Settings shows "Rescue User" role
7. **Check** → SOS screen shows "RESCUE" mode

### Test 3: All Role Transitions
1. **Start as** → SOS User (RED)
2. **Switch to** → Rescue User (BLUE) → Verify UI changes
3. **Switch to** → Relay User (GREEN) → Verify UI changes  
4. **Switch back to** → SOS User (RED) → Verify UI changes
5. **Verify** → Each transition updates theme colors immediately
6. **Verify** → Each role shows correct description and icon

### Test 4: Service Integration
1. **Start with** → SOS User
2. **Enable** → Device discovery/scanning
3. **Switch to** → Rescue User
4. **Verify** → Device re-advertises with new role name
5. **Check logs** → ServiceCoordinator updates all services
6. **Verify** → Other devices see role change immediately

### Test 5: Error Handling
1. **Test** → Role switching without internet (should work offline)
2. **Test** → Rapid role switching (should handle gracefully)
3. **Test** → App interruption during role switch (should recover)

## Expected Behaviors

### UI Behavior
- **SOS User**: RED theme, "SOS" button in SOS screen, warning icon
- **Rescue User**: BLUE theme, "RESCUE" button in SOS screen, shield icon
- **Relay User**: GREEN theme, relay/WiFi icon, normal SOS behavior

### Persistence Behavior
- Role changes stored immediately in SQLite + SharedPreferences
- Survives app restarts and device reboots
- Syncs to cloud when internet available

### Service Behavior
- Device advertises with new role in name: "John_RESCUER", "Alice_SOS"  
- All communication services restart with new role
- Mesh network propagates role change to connected devices

## File Changes Summary

### Modified Files:
1. **`settings_screen.dart`** - Added role switching UI and logic
2. **`auth_service.dart`** - Added `updateRole()` method with ServiceCoordinator integration
3. **`service_coordinator.dart`** - Added `updateDeviceRole()` method for service re-registration
4. **`home_screen.dart`** - Updated role mapping for consistency
5. **`main_app.dart`** - Fixed auth check to use real AuthService

### Key Methods Added:
- `AuthService.updateRole(String newRole)` - Updates user role with persistence
- `ServiceCoordinator.updateDeviceRole(String newRole)` - Re-registers device with new role
- `SettingsScreen._showRoleSwitchDialog()` - Role selection UI
- `SettingsScreen._confirmRoleSwitch()` - Role change confirmation
- `SettingsScreen._switchRole()` - Executes role change with loading states

## Validation Checklist

- [ ] ✅ Role switching UI appears in Settings
- [ ] ✅ Current role displayed with color coding
- [ ] ✅ Role selection dialog shows all three roles
- [ ] ✅ Confirmation dialog prevents accidental changes
- [ ] ✅ Loading indicator during role switch
- [ ] ✅ Success/error messages displayed
- [ ] ✅ UI theme updates immediately after role change
- [ ] ✅ Role persists through app restarts
- [ ] ✅ ServiceCoordinator re-registers device
- [ ] ✅ All screens update with new role consistently
- [ ] ✅ Works offline (SQLite storage)
- [ ] ✅ Real authentication flow on app startup

## Integration Status: ✅ COMPLETE

The role switching functionality is fully implemented and ready for testing. Users can now seamlessly switch between SOS, Rescue, and Relay roles without needing to re-register, with immediate UI updates and proper service integration.