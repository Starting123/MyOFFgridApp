# Off-Grid SOS App - Comprehensive Test Validation

## Test Environment Setup

### Prerequisites
- **Devices:** Minimum 2 physical Android devices (emulators have limited P2P support)
- **OS Version:** Android 6.0+ (API level 23+)
- **Permissions:** Location, Bluetooth, WiFi, Storage granted on all devices
- **Network:** Test both with and without internet connectivity
- **Distance:** Devices within 30-100 meters for reliable P2P connection

### Test Data
- **User A:** Name="Alice", Phone="123-456-7890", Role=SOS User
- **User B:** Name="Bob", Phone="098-765-4321", Role=Rescue User  
- **User C:** Name="Charlie", Phone="555-123-4567", Role=Relay Node

---

## Test Scenario 1: Registration and Authentication Flow

### Duration: 15 minutes
### Devices: Device A, Device B

#### Test Steps

**1.1 First Launch Registration (Device A)**
```
Action: Launch app for first time
Expected: Registration screen appears automatically
UI Check: Logo, "Create Your Profile" title, form fields visible

Action: Fill form - Name: "Alice", Phone: "123-456-7890"
Expected: Input validation passes, no error messages

Action: Select "SOS User" role card (RED)
Expected: Card highlights, role description shows, RED theme preview

Action: Tap "Create Profile" button
Expected: Loading spinner, then success message "Profile created successfully!"

Result Check: 
- Home screen loads with RED theme
- Large red "SOS" button visible
- Status bar shows "SOS User" mode
- Settings accessible via menu
```

**1.2 Repeat Registration (Device B)**
```
Action: Launch app, complete registration as "Bob", "Rescue User" (BLUE)
Expected: Blue themed home screen, "RESCUE" button visible
```

**1.3 Role Switching Test (Device A)**
```
Action: Navigate Home → Settings → Role Switching section
Expected: Current role shows "SOS User" with red badge

Action: Tap "Change Role" button
Expected: Dialog with 3 role options (SOS/Rescue/Relay) appears

Action: Select "Rescue User" → Confirm "Yes, Switch Role"
Expected: Loading spinner, success message, UI theme changes to BLUE

Action: Navigate back to Home screen
Expected: Blue theme, "RESCUE" button, "Rescue User" in status
```

**1.4 Persistence Test**
```
Action: Force close both apps, relaunch
Expected: Both apps open directly to main screen (no registration)
Expected: Device A = blue theme, Device B = blue theme
Expected: Settings show correct roles for each device
```

#### Success Criteria
- [x] Registration creates user profile and stores in SQLite
- [x] Role selection affects UI theme immediately  
- [x] Role switching works without re-registration
- [x] User state persists through app restarts
- [x] Auth check properly routes to main app on subsequent launches

---

## Test Scenario 2: SOS Broadcasting and Rescue Discovery

### Duration: 12 minutes
### Devices: Device A (SOS), Device B (Rescuer)

#### Test Setup
```
Device A: Set role to "SOS User" (red theme)
Device B: Set role to "Rescue User" (blue theme)
Distance: 10-50 meters apart
Permissions: Ensure location, Bluetooth, WiFi granted
```

#### Test Steps

**2.1 SOS Signal Broadcast**
```
Device A Action: Tap large red "SOS" button on home screen
Expected UI: Button text changes to "BROADCASTING SOS..."
Expected UI: Progress indicators show service status (Green = active)
Expected Logs: 
  📡 ServiceCoordinator: Broadcasting SOS signal
  🔍 NearbyService: Starting advertising as 'Alice_SOS'
  📶 P2PService: Creating emergency group
  🔵 BLEService: BLE advertising with emergency flag
  📍 LocationService: GPS coordinates acquired

Device A Verification:
- SOS button shows "STOP SOS" (toggle state)
- Service status indicators: Nearby (Green), BLE (Green), WiFi (Green)
- Location permission granted (if prompted)
- Emergency signal active on all available protocols
```

**2.2 Rescue Signal Detection**
```
Device B Action: Navigate to Home screen, check "SOS Signals" section
Expected UI: "Alice" card appears in SOS signals list
Card Content Check:
  - Name: "Alice"
  - Phone: "123-456-7890" 
  - Distance: "<50m" or actual distance
  - Signal strength indicator (bars/percentage)
  - Red emergency icon
  - Timestamp of signal

Expected Logs:
  🔍 NearbyService: Discovered endpoint 'Alice_SOS'
  📡 ServiceCoordinator: SOS signal detected from Alice
  💾 LocalDatabaseService: Emergency contact stored
```

**2.3 Direct Communication**
```
Device B Action: Tap on Alice's SOS card
Expected: Chat screen opens with "Alice" as title
Expected: Empty chat (first contact) or previous messages

Device B Action: Type message "Help is on the way! What's your exact location?"
Expected: Message appears in chat as "sent" (blue bubble, right aligned)

Device A Check: Chat notification appears, message visible in chat
Device A Action: Reply "I'm at Central Park, near the playground. Injured ankle."
Device B Check: Reply appears in chat (gray bubble, left aligned)

Message Status Verification:
- Sending: Loading spinner
- Sent: Checkmark icon  
- Delivered: Double checkmark
- Failed: Red X with retry option
```

#### Success Criteria
- [x] SOS broadcast activates multiple communication protocols
- [x] SOS signals discoverable by rescue devices in range
- [x] Signal information (name, location, distance) displays correctly
- [x] Direct chat communication works bidirectionally
- [x] Message delivery status tracking functions properly

---

## Test Scenario 3: Multi-Protocol Communication and Mesh Networking

### Duration: 20 minutes  
### Devices: Device A (SOS), Device B (Rescuer), Device C (Relay)

#### Test Setup
```
Device A: "Alice", SOS User (RED theme)
Device B: "Bob", Rescue User (BLUE theme)  
Device C: "Charlie", Relay Node (GREEN theme)
Physical Layout: Test both direct connection and mesh relay scenarios
```

#### Test Steps

**3.1 Nearby Connections Protocol Test**
```
Setup: Devices A & B within 30 meters, WiFi enabled
Device A: Start SOS broadcast
Device B: Monitor connection logs

Expected Connection Logs:
  🔍 NearbyService: Advertising started
  🔍 NearbyService: Discovery started  
  🤝 NearbyService: Connection request from 'Bob_RESCUER'
  ✅ NearbyService: Connected to endpoint 'Alice_SOS'

Message Test:
Device B → A: "Testing Nearby Connections"
Expected: Message delivers with "via Nearby" in debug logs
```

**3.2 BLE Fallback Protocol Test**
```
Setup: Disable WiFi on both devices, keep Bluetooth enabled
Device A: Continue SOS broadcast (should fallback to BLE)
Device B: Should maintain connection via BLE

Expected Connection Logs:
  📶 NearbyService: WiFi unavailable, falling back
  🔵 BLEService: Starting BLE scan
  🔵 BLEService: Discovered device 'Alice_SOS'
  ✅ BLEService: BLE connection established

Message Test:
Device B → A: "Testing BLE fallback"
Expected: Message delivers with "via BLE" in debug logs
```

**3.3 WiFi Direct Protocol Test**
```
Setup: Re-enable WiFi, test WiFi Direct capabilities
Device A: SOS broadcast should use WiFi Direct for high bandwidth
Device B: Connect via WiFi Direct

Expected Connection Logs:
  📶 P2PService: WiFi Direct group created
  📶 P2PService: Peer 'Bob_RESCUER' joined group
  ✅ P2PService: Direct connection established

File Transfer Test:
Device B → A: Send image attachment
Expected: File transfers successfully via WiFi Direct
```

**3.4 Mesh Network Relay Test**
```
Setup: Position devices A ←→ C ←→ B (C in middle, A & B out of direct range)
Device C: Activate "Relay Node" mode (green theme)

Device A: Send SOS signal
Expected: Signal reaches Device B through Device C relay

Expected Mesh Logs:
  🌐 MeshNetworkService: Route discovered via Charlie_RELAY
  🔄 MeshNetworkService: Forwarding message (TTL: 5)
  ✅ MeshNetworkService: Message delivered via relay

Message Relay Test:
Device A → C → B: "Emergency message via mesh"
Device B → C → A: "Received via relay network"
Expected: Both messages deliver successfully through Device C
```

#### Success Criteria
- [x] All three protocols (Nearby/BLE/WiFi Direct) function independently
- [x] Automatic fallback between protocols based on availability
- [x] Mesh networking enables extended range communication
- [x] Message routing through relay nodes works correctly
- [x] Protocol selection logged and visible in debug information

---

## Test Scenario 4: Offline Operation and Message Queuing

### Duration: 18 minutes
### Devices: Device A, Device B

#### Test Setup
```
Initial: Both devices connected to internet and each other
Test offline operation, message queuing, and synchronization
```

#### Test Steps

**4.1 Internet Disconnection Test**
```
Action: Turn on airplane mode, then re-enable Bluetooth and WiFi Direct
Verification: Apps should continue working for local P2P communication
Device A → B: Send message "Testing offline mode"
Expected: Message delivers via local P2P, marked as "Sent" (not "Synced")

Database Check:
- Message stored in SQLite with syncedToCloud = 0
- Local delivery confirmed via P2P protocols
- No cloud sync indicators (gray instead of green)
```

**4.2 Message Queue Test**
```
Setup: Move Device A out of range of Device B (>100 meters apart)
Device A: Send 3 messages:
  1. "Message 1 - queued"
  2. "Message 2 - queued"  
  3. "Message 3 - queued"

Expected UI: Messages show "Pending" status with clock icon
Expected Logs:
  📤 ServiceCoordinator: No active connections, queuing message
  💾 EnhancedMessageQueueService: Message added to queue
  ⏰ MessageQueue: 3 messages pending delivery

Device Movement: Bring Device A back within range of Device B
Expected: All 3 queued messages deliver automatically
Expected Logs:
  🔄 ServiceCoordinator: Connection restored, processing queue
  ✅ MessageQueue: 3 messages delivered successfully
```

**4.3 Cloud Synchronization Test**
```
Action: Reconnect both devices to internet
Expected: All messages sync to cloud automatically

UI Verification:
- Messages show "Synced" status with green cloud icon
- Sync timestamp updated in message details

Database Verification:
- syncedToCloud = 1 for all messages
- lastSyncTimestamp updated
- Cloud backup indicators active

Expected Logs:
  ☁️ CloudSyncService: Syncing 6 messages to cloud
  ✅ CloudSyncService: All messages synced successfully
  💾 LocalDatabaseService: Sync status updated
```

**4.4 Cross-Device Synchronization**
```
Setup: Both devices online, same user account
Device A: Add new contact, send message
Device B: Should receive contact and message via cloud sync

Expected: Real-time sync between devices when online
Timeout: Sync should complete within 30 seconds
```

#### Success Criteria
- [x] App functions completely offline for local P2P communication
- [x] Message queuing works when devices out of range
- [x] Automatic message delivery when connection restored
- [x] Cloud synchronization resumes when internet available
- [x] Cross-device sync maintains consistency

---

## Test Scenario 5: Error Handling and Recovery

### Duration: 10 minutes
### Devices: Device A, Device B

#### Test Steps

**5.1 Connection Failure Recovery**
```
Setup: Establish connection between devices
Action: Forcibly interrupt connection (turn off Bluetooth mid-message)
Expected: Error handling gracefully, retry mechanism activates

Expected UI: "Connection lost, retrying..." message
Expected Logs:
  ❌ ServiceCoordinator: Connection lost to Bob_RESCUER
  🔄 ServiceCoordinator: Attempting reconnection (1/3)
  ✅ ServiceCoordinator: Connection restored
```

**5.2 Permission Denial Recovery**
```
Action: Revoke location permission during SOS broadcast
Expected: App requests permission again with explanation
Expected: Graceful degradation (SOS works without precise location)

UI Check: Clear error message, actionable "Grant Permission" button
Recovery Check: Re-granting permission resumes full functionality
```

**5.3 Low Battery Optimization**
```
Setup: Enable battery optimization for the app
Action: Send app to background during SOS broadcast
Expected: Foreground service keeps SOS active
Expected: Battery optimization warning with instructions to disable
```

#### Success Criteria  
- [x] Graceful error handling with user-friendly messages
- [x] Automatic retry mechanisms for failed operations
- [x] Permission issues handled with clear recovery steps
- [x] Background operation continues during battery optimization

---

## Expected Performance Benchmarks

### Discovery and Connection Times
- **Device Discovery:** 5-15 seconds in optimal conditions
- **Connection Establishment:** 3-8 seconds
- **Message Delivery:** 1-5 seconds local, 10-30 seconds via mesh
- **SOS Signal Range:** 30-100 meters (environment dependent)

### Resource Usage
- **Battery:** 5-15% drain per hour during active scanning
- **RAM:** 50-150 MB typical usage
- **Storage:** 10-50 MB per 1000 messages
- **Network:** Minimal data usage when online (sync only)

### Reliability Targets
- **Message Delivery Success:** >95% in normal conditions
- **Connection Success Rate:** >90% within range
- **App Stability:** <1 crash per 100 hours of operation
- **Data Integrity:** 100% message persistence guarantee