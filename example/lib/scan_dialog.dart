import 'package:flutter/material.dart';
import 'package:flutter_cast_plus/flutter_cast_plus.dart';

class ScanDialog extends StatefulWidget {
  const ScanDialog({super.key});

  @override
  State<ScanDialog> createState() => _ScanDialogState();
}

class _ScanDialogState extends State<ScanDialog> {
  List<CastDevice> devices = [];

  @override
  void initState() {
    scanDevices();
    super.initState();
  }

  Future<void> scanDevices() async {
    devices = await FlutterClassPlusPlugin().scanDevices(
      types: [CastDeviceType.chromeCast],
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Device'),
      content: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];

          return ListTile(
            onTap: () async {
              final connected = await device.service.connect();

              if (connected) {
                await device.service.launch();
                // ignore: use_build_context_synchronously
                return Navigator.pop(context, device);
              } else {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to connect'),
                  ),
                );
              }
            },
            title: Text(device.friendlyName ?? ''),
            subtitle: Text(device.host ?? ''),
            trailing: const Icon(Icons.chevron_right),
          );
        },
      ),
    );
  }
}
