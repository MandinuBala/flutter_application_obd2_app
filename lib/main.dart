import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OBD2 App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? characteristic;

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    // Listen to scan results
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        print('Found device: ${r.device.name} (${r.device.id})');

        // Look for ELM327 device
        if (r.device.name.toLowerCase().contains('obd') ||
            r.device.name.toLowerCase().contains('elm')) {
          connectToDevice(r.device);
          FlutterBluePlus.stopScan();
          break;
        }
      }
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() {
      connectedDevice = device;
    });

    // Discover services
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var c in service.characteristics) {
        if (c.properties.write && c.properties.read) {
          characteristic = c;
          print('Characteristic found');
          break;
        }
      }
    }
  }

  void sendCommand(String command) async {
    if (characteristic == null) return;
    List<int> bytes = command.codeUnits;
    await characteristic!.write(bytes, withoutResponse: true);
  }

  void readResponse() async {
    if (characteristic == null) return;
    var response = await characteristic!.read();
    print('Response: $response');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OBD2 App')),
      body: Center(
        child:
            connectedDevice == null
                ? const Text('Scanning for OBD device...')
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Connected to ${connectedDevice!.name}'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        sendCommand('010C\r'); // Request RPM
                      },
                      child: const Text('Request RPM'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        readResponse();
                      },
                      child: const Text('Read Response'),
                    ),
                  ],
                ),
      ),
    );
  }
}
