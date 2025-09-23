import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model for nearby devices
class NearbyDevice {
  final String id;
  final String name;
  final String type; // 'sos' or 'rescuer'

  NearbyDevice({required this.id, required this.name, required this.type});
}

// Providers
final sosActiveProvider = NotifierProvider<SOSNotifier, bool>(() {
  return SOSNotifier();
});

final rescuerModeProvider = NotifierProvider<RescuerModeNotifier, bool>(() {
  return RescuerModeNotifier();
});

final nearbyDevicesProvider = NotifierProvider<NearbyDevicesNotifier, List<NearbyDevice>>(() {
  return NearbyDevicesNotifier();
});

// State Notifiers
class SOSNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
    // TODO: Trigger P2P broadcast when SOS is active
    if (state) {
      // Start broadcasting SOS signal
      // P2PService.instance.broadcast({'type': 'sos', 'active': true});
    } else {
      // Stop broadcasting SOS signal
      // P2PService.instance.stopDiscovery();
    }
  }
}

class RescuerModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
    // TODO: Start/stop scanning for SOS signals
    if (state) {
      // P2PService.instance.startDiscovery();
    } else {
      // P2PService.instance.stopDiscovery();
    }
  }
}

class NearbyDevicesNotifier extends Notifier<List<NearbyDevice>> {
  @override
  List<NearbyDevice> build() => [
    NearbyDevice(id: '1', name: 'Device 1', type: 'sos'),
    NearbyDevice(id: '2', name: 'Device 2', type: 'rescuer'),
  ];

  void addDevice(NearbyDevice device) {
    state = [...state, device];
  }

  void removeDevice(String id) {
    state = state.where((device) => device.id != id).toList();
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosActive = ref.watch(sosActiveProvider);
    final rescuerMode = ref.watch(rescuerModeProvider);
    final nearbyDevices = ref.watch(nearbyDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Off-Grid SOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => Navigator.pushNamed(context, '/chat'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // SOS Button
            Expanded(
              flex: 2,
              child: Center(
                child: GestureDetector(
                  onTap: () => ref.read(sosActiveProvider.notifier).toggle(),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sosActive ? Colors.red : Colors.grey,
                      boxShadow: [
                        BoxShadow(
                          color: sosActive ? Colors.red.withOpacity(0.3) : Colors.black12,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Rescuer Mode Switch
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                color: rescuerMode ? Colors.blue.withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Rescuer Mode',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: rescuerMode,
                    onChanged: (value) => ref.read(rescuerModeProvider.notifier).toggle(),
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nearby Devices List
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nearby Devices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 3,
              child: ListView.builder(
                itemCount: nearbyDevices.length,
                itemBuilder: (context, index) {
                  final device = nearbyDevices[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.phone_android,
                        color: device.type == 'sos' ? Colors.red : Colors.blue,
                      ),
                      title: Text(device.name),
                      subtitle: Text(device.type == 'sos' ? 'SOS Active' : 'Online'),
                      trailing: device.type == 'sos'
                          ? const Icon(Icons.warning, color: Colors.red)
                          : IconButton(
                              icon: const Icon(Icons.message),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/chat',
                                  arguments: device,
                                );
                              },
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
