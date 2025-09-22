import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool sosActive = false;
  bool isRescuer = false;

  final List<String> nearbyDevices = [
    'Device A',
    'Device B',
    'Device C',
  ];

  void toggleSOS() {
    setState(() {
      sosActive = !sosActive;
    });
  }

  void toggleRescuer() {
    setState(() {
      isRescuer = !isRescuer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Off-Grid SOS'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: sosActive ? Colors.red[700] : Colors.red,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: toggleSOS,
              child: Text(
                sosActive ? 'SOS ACTIVE' : 'SEND SOS',
                style: const TextStyle(fontSize: 22, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isRescuer ? Colors.blue[700] : Colors.blue,
                minimumSize: const Size(double.infinity, 52),
              ),
              onPressed: toggleRescuer,
              child: Text(
                isRescuer ? 'Rescuer Mode: ON' : 'Rescuer Mode: OFF',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nearby Devices',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: nearbyDevices.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.wifi_tethering),
                      title: Text(nearbyDevices[index]),
                      subtitle: const Text('Distance: ~5m (dummy)'),
                      trailing: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Connect'),
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
