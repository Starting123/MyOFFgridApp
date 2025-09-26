# Off-Grid SOS & Nearby Share - Testing Scenarios

This document provides comprehensive testing scenarios for validating the Off-Grid SOS application on real devices. These tests ensure all features work correctly in offline and multi-device environments.

## Prerequisites

### Hardware Requirements
- **Minimum 2 Android devices** (API level 21+)
- **Recommended 3+ devices** for mesh network testing
- Devices should support:
  - Bluetooth Low Energy (BLE)
  - WiFi Direct
  - Location services
  - Camera (for image/video testing)

### Software Requirements
- Flutter app installed on all test devices
- Location permissions granted
- Bluetooth enabled
- WiFi can be disabled (for offline testing)

---

## Test Scenario 1: Basic User Registration & Authentication

### Objective
Verify user registration and login functionality works offline-first.

### Steps
**Device A & B:**
1. Launch the Off-Grid SOS app
2. If first time: Complete registration
   - Enter name, phone number
   - Select user role (SOS User, Rescuer, or Relay)
   - Grant all requested permissions
3. Verify user profile appears in settings
4. Test logout and login functionality

### Expected Results
- ✅ Registration completes successfully
- ✅ User data persists locally
- ✅ Role selection works correctly
- ✅ Settings screen shows user profile

---

## Test Scenario 2: SOS Mode Toggle & Broadcasting

### Objective
Test SOS activation, broadcasting, and rescuer detection.

### Steps
**Device A (SOS User):**
1. Open app and go to SOS screen
2. Tap the large red SOS button
3. Verify SOS mode activates with red indicator
4. Check that SOS signal is being broadcast
5. Wait 30 seconds, then tap SOS button again to deactivate

**Device B (Rescuer):**
1. Open app and enable "Rescuer Mode" toggle
2. Navigate to nearby devices screen
3. Should detect Device A's SOS signal within 10-30 seconds
4. Verify SOS device appears with red indicator
5. Tap on SOS device to initiate chat

### Expected Results
- ✅ SOS button toggles correctly (red when active)
- ✅ Rescuer device detects SOS signal automatically
- ✅ Real-time status updates work
- ✅ Chat opens when tapping SOS device

---

## Test Scenario 3: Offline P2P Messaging

### Objective
Validate peer-to-peer messaging works without internet connectivity.

### Setup
**Both Devices:**
1. **Disable WiFi and Mobile Data** (critical for offline testing)
2. Keep Bluetooth and Location enabled
3. Ensure devices are within 10 meters of each other

### Steps
1. **Device A:** Activate SOS mode
2. **Device B:** Enable Rescuer mode and connect to Device A
3. **Send Messages:**
   - Text: "Emergency assistance needed!"
   - Image: Take and send a photo
   - Location: Share current GPS coordinates
4. **Verify Delivery:**
   - Check message status indicators (pending → sent → delivered)
   - Confirm messages appear on both devices
5. **Bidirectional Testing:**
   - Device B sends reply: "Help is on the way, stay calm"
   - Device A acknowledges: "Thank you, I'm at the bridge"

### Expected Results
- ✅ All message types send successfully offline
- ✅ Delivery status indicators work correctly
- ✅ Messages persist in local database
- ✅ Real-time message sync between devices

---

## Test Scenario 4: Multi-Device Mesh Network

### Objective
Test multi-hop message routing through intermediate devices.

### Setup
**Device Layout:**
```
Device A (SOS) ←→ Device B (Relay) ←→ Device C (Rescuer)
   Range: 10m      Range: 10m      Range: N/A
```

Position devices so A and C are out of direct range but can communicate through B.

### Steps
1. **Device A:** Activate SOS mode
2. **Device B:** Set to Normal/Relay mode (acts as intermediary)
3. **Device C:** Enable Rescuer mode
4. **Test Mesh Routing:**
   - Device A sends SOS broadcast
   - Message should route: A → B → C
   - Device C should receive SOS signal through mesh
5. **Test Chat Through Mesh:**
   - Device C responds to SOS
   - Message should route: C → B → A
   - Verify conversation works through intermediate hops

### Expected Results
- ✅ SOS signals reach destination through mesh routing
- ✅ Chat messages route through intermediate devices
- ✅ TTL (Time-to-Live) prevents infinite loops
- ✅ Multiple routing paths work if available

---

## Test Scenario 5: Network Recovery & Sync

### Objective
Test app behavior during network connectivity changes and cloud sync.

### Steps
1. **Offline Phase:**
   - Complete Scenario 3 (P2P messaging) while offline
   - Send 5+ messages between devices
   - Verify all messages stored locally

2. **Network Recovery:**
   - Re-enable WiFi/Mobile Data on both devices
   - Wait 1-2 minutes for automatic sync
   - Check that messages sync to cloud (if configured)

3. **Cross-Device Sync:**
   - Install app on a third device
   - Login with same user account
   - Verify message history appears on new device

### Expected Results
- ✅ App works fully offline
- ✅ Automatic sync when connectivity restored
- ✅ Message history syncs across devices
- ✅ No message loss during connectivity changes

---

## Test Scenario 6: Background Operation & Battery Optimization

### Objective
Verify app continues working when backgrounded or device is locked.

### Steps
1. Start SOS or Rescuer mode on Device A
2. Press home button (app goes to background)
3. Lock the device screen
4. On Device B, try to connect and send messages
5. Wake Device A and check if messages were received
6. Test for 10+ minutes of background operation

### Expected Results
- ✅ Device discovery continues in background
- ✅ Messages received when app backgrounded
- ✅ SOS signals continue broadcasting when locked
- ✅ Reasonable battery consumption

---

## Test Scenario 7: Error Handling & Recovery

### Objective
Test app stability under error conditions.

### Steps
1. **Bluetooth Interference:**
   - Turn Bluetooth off/on during connection
   - Verify automatic reconnection

2. **Out of Range:**
   - Move devices apart until connection lost
   - Move back into range
   - Check automatic reconnection

3. **Permission Revocation:**
   - Revoke location permission during operation
   - App should prompt for re-permission
   - Restore permission and verify recovery

4. **App Crash Recovery:**
   - Force-close app during message sending
   - Restart app
   - Check message status and retry mechanism

### Expected Results
- ✅ Graceful handling of connectivity issues
- ✅ Automatic retry mechanisms work
- ✅ Clear error messages for users
- ✅ App recovers from crashes without data loss

---

## Test Scenario 8: Performance & Scalability

### Objective
Test app performance with multiple devices and high message volume.

### Steps
1. **Multiple Device Discovery:**
   - Use 5+ devices if available
   - All should discover each other within 60 seconds
   - Verify mesh topology builds correctly

2. **High Message Volume:**
   - Send 20+ messages rapidly between devices
   - Include mix of text, images, and location data
   - Monitor for message loss or UI lag

3. **Extended Runtime:**
   - Run continuous operation for 30+ minutes
   - Monitor memory usage and battery drain
   - Check for performance degradation

### Expected Results
- ✅ Stable discovery with multiple devices
- ✅ No message loss under high volume
- ✅ Responsive UI under load
- ✅ Stable memory usage over time

---

## Validation Checklist

After completing all scenarios, verify:

### Core Functionality
- [ ] App works completely offline
- [ ] Device-to-device communication via Bluetooth, WiFi Direct, and Nearby
- [ ] Message queueing and sync when connectivity restored
- [ ] User registration and authentication

### SOS Features
- [ ] SOS toggle works with visual indicators
- [ ] SOS signals broadcast to nearby rescuers
- [ ] 1-to-1 chat opens from SOS signals
- [ ] GPS location sharing in emergency messages
- [ ] Real-time status updates

### Chat System
- [ ] Text, image, and video messages work
- [ ] Message delivery tracking (pending/sent/delivered/synced)
- [ ] Offline-first with local database storage
- [ ] Cloud sync when online

### Networking
- [ ] Multi-hop mesh routing works
- [ ] Real-time device discovery
- [ ] Priority fallback (WiFi → Bluetooth → Nearby)
- [ ] Network topology adapts to device changes

### UI/UX
- [ ] All required screens present and functional
- [ ] Role selection works correctly
- [ ] Settings toggles control services properly
- [ ] Delivery indicators show correctly in chat

### Technical Quality
- [ ] No crashes or unhandled exceptions
- [ ] Responsive UI under all conditions
- [ ] Proper error messages and recovery
- [ ] Battery usage is reasonable

---

## Troubleshooting Common Issues

### Device Discovery Fails
1. Check all permissions are granted
2. Ensure Bluetooth and Location are enabled
3. Try restarting Bluetooth services
4. Verify devices are within range (10-30 meters)

### Messages Not Sending
1. Check connection status in app
2. Verify target device is still connected
3. Try toggling airplane mode to reset connections
4. Check local message queue in database

### SOS Not Detected
1. Ensure one device is in SOS mode, other in Rescuer mode
2. Check if devices can discover each other normally first
3. Verify location permissions on rescuer device
4. Try restarting discovery process

### Poor Performance
1. Close other Bluetooth-heavy apps
2. Ensure devices have adequate battery
3. Check for device-specific Bluetooth issues
4. Try on different device models

---

## Test Results Template

Copy this template for documenting test results:

```
Test Date: ___________
Devices Used: ___________
App Version: ___________

Scenario 1 - Registration: PASS / FAIL
Issues: ___________

Scenario 2 - SOS Toggle: PASS / FAIL  
Issues: ___________

Scenario 3 - P2P Messaging: PASS / FAIL
Issues: ___________

Scenario 4 - Mesh Network: PASS / FAIL
Issues: ___________

Scenario 5 - Network Recovery: PASS / FAIL
Issues: ___________

Scenario 6 - Background Operation: PASS / FAIL
Issues: ___________

Scenario 7 - Error Handling: PASS / FAIL
Issues: ___________

Scenario 8 - Performance: PASS / FAIL
Issues: ___________

Overall Grade: A / B / C / D / F
Production Ready: YES / NO
```

---

## Next Steps

After successful testing:
1. Document any issues found
2. Verify fixes for failed test cases
3. Re-test critical scenarios
4. Prepare for production deployment
5. Create user documentation based on test learnings