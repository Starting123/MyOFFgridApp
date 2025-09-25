import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/enhanced_sos_provider.dart';
import '../../services/sos_broadcast_service.dart';

class EnhancedSOSScreen extends ConsumerStatefulWidget {
  const EnhancedSOSScreen({super.key});
  
  @override
  ConsumerState<EnhancedSOSScreen> createState() => _EnhancedSOSScreenState();
}

class _EnhancedSOSScreenState extends ConsumerState<EnhancedSOSScreen> {
  final TextEditingController _emergencyMessageController = TextEditingController(
    text: 'EMERGENCY! Need immediate assistance. Please help!',
  );
  final TextEditingController _responseController = TextEditingController();

  @override
  void dispose() {
    _emergencyMessageController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('🆘 Emergency SOS'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: sosState.when(
        data: (state) => _buildSOSInterface(state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(sosProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSInterface(SOSAppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Card
          _buildStatusCard(state),
          
          const SizedBox(height: 20),
          
          // SOS Mode Selection
          _buildModeSelection(state),
          
          const SizedBox(height: 20),
          
          // Emergency Message Input (for Victim Mode)
          if (state.currentMode == SOSMode.victim || state.currentMode == SOSMode.disabled)
            _buildEmergencyMessageCard(),
          
          const SizedBox(height: 20),
          
          // Active SOS Broadcasts (for Rescuer Mode)
          if (state.currentMode == SOSMode.rescuer)
            _buildActiveSOSCard(state),
          
          const SizedBox(height: 20),
          
          // Device Discovery Card
          _buildDeviceDiscoveryCard(state),
          
          // Connection Status
          _buildConnectionStatus(state),
        ],
      ),
    );
  }

  Widget _buildStatusCard(SOSAppState state) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (state.currentMode) {
      case SOSMode.victim:
        statusColor = Colors.red;
        statusText = '🚨 VICTIM MODE ACTIVE';
        statusIcon = Icons.emergency;
        break;
      case SOSMode.rescuer:
        statusColor = Colors.blue;
        statusText = '🔵 RESCUER MODE ACTIVE';
        statusIcon = Icons.medical_services;
        break;
      case SOSMode.disabled:
        statusColor = Colors.grey;
        statusText = '⚪ NORMAL MODE';
        statusIcon = Icons.chat;
        break;
    }
    
    return Card(
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [statusColor.withValues(alpha: 0.1), statusColor.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(statusIcon, size: 48, color: statusColor),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            if (state.lastLocation != null)
              Text(
                '📍 ${state.lastLocation}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            if (state.error != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => ref.read(sosProvider.notifier).clearError(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelection(SOSAppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Mode',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Victim Mode Button
            ElevatedButton.icon(
              onPressed: state.currentMode == SOSMode.victim 
                  ? () => ref.read(sosProvider.notifier).disableSOSMode()
                  : () => _activateVictimMode(),
              icon: const Icon(Icons.emergency),
              label: Text(state.currentMode == SOSMode.victim ? 'STOP SOS' : 'ACTIVATE SOS (VICTIM)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: state.currentMode == SOSMode.victim ? Colors.grey : Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Rescuer Mode Button
            ElevatedButton.icon(
              onPressed: state.currentMode == SOSMode.rescuer
                  ? () => ref.read(sosProvider.notifier).disableSOSMode()
                  : () => ref.read(sosProvider.notifier).activateRescuerMode(),
              icon: const Icon(Icons.medical_services),
              label: Text(state.currentMode == SOSMode.rescuer ? 'STOP RESCUER' : 'ACTIVATE RESCUER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: state.currentMode == SOSMode.rescuer ? Colors.grey : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Normal Mode Button
            if (state.currentMode != SOSMode.disabled)
              TextButton.icon(
                onPressed: () => ref.read(sosProvider.notifier).disableSOSMode(),
                icon: const Icon(Icons.chat),
                label: const Text('NORMAL CHAT MODE'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyMessageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Emergency Message',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emergencyMessageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe your emergency...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSOSCard(SOSAppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Active SOS Broadcasts (${state.activeSOS.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            if (state.activeSOS.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No active SOS broadcasts.\nWaiting for emergency signals...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...state.activeSOS.map((sos) => _buildSOSBroadcastTile(sos)),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSBroadcastTile(SOSBroadcast sos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emergency, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SOS from ${sos.victimId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                _formatTime(sos.timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(sos.message),
          
          if (sos.latitude != null && sos.longitude != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Location: ${sos.latitude!.toStringAsFixed(4)}, ${sos.longitude!.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _responseController,
                  decoration: const InputDecoration(
                    hintText: 'Response message...',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _respondToSOS(sos),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('RESPOND', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceDiscoveryCard(SOSAppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Device Discovery',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ref.read(sosProvider.notifier).startDiscovery(),
                    icon: const Icon(Icons.search),
                    label: const Text('START DISCOVERY'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ref.read(sosProvider.notifier).stopDiscovery(),
                    icon: const Icon(Icons.stop),
                    label: const Text('STOP'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Nearby Devices (${state.nearbyDevices.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            
            if (state.nearbyDevices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'No nearby devices found',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...state.nearbyDevices.map((device) => ListTile(
                leading: const Icon(Icons.devices),
                title: Text(device['endpointName'] ?? 'Unknown Device'),
                subtitle: Text('ID: ${device['endpointId']}'),
                trailing: const Icon(Icons.link, color: Colors.green),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(SOSAppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              state.connectedDevicesCount > 0 ? Icons.wifi : Icons.wifi_off,
              color: state.connectedDevicesCount > 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text('Connected: ${state.connectedDevicesCount} devices'),
            const Spacer(),
            Icon(
              state.isLocationEnabled ? Icons.location_on : Icons.location_off,
              color: state.isLocationEnabled ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(state.isLocationEnabled ? 'GPS ON' : 'GPS OFF'),
          ],
        ),
      ),
    );
  }

  void _activateVictimMode() {
    final message = _emergencyMessageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an emergency message')),
      );
      return;
    }
    
    ref.read(sosProvider.notifier).activateVictimMode(message);
  }

  void _respondToSOS(SOSBroadcast sos) {
    final response = _responseController.text.trim();
    if (response.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a response message')),
      );
      return;
    }
    
    ref.read(sosProvider.notifier).respondToSOS(sos, response);
    _responseController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Response sent to victim')),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}