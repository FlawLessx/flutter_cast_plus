import 'package:flutter_cast_plus/src/model/_index.dart';
import 'package:multicast_dns/multicast_dns.dart';

class FlutterClassPlusPlugin {
  Future<List<CastDevice>> scanDevices({List<CastDeviceType>? types}) async {
    List<CastDeviceType> selectedTypes =
        types ?? [CastDeviceType.appleTV, CastDeviceType.chromeCast];
    final MDnsClient client = MDnsClient();
    List<CastDevice> results = [];

    // Start the client with default options.
    await client.start();

    for (var tcp in selectedTypes.map((e) => castDeviceType2TCP(e)).toList()) {
      // Get the PTR recod for the service.
      await for (PtrResourceRecord ptr in client
          .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(tcp))) {
        // Use the domainName from the PTR record to get the SRV record,
        // which will have the port and local hostname.
        // Note that duplicate messages may come through, especially if any
        // other mDNS queries are running elsewhere on the machine.
        await for (SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName))) {
          await for (IPAddressResourceRecord ip
              in client.lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(srv.target))) {
            final device = CastDevice(
              name: srv.name,
              host: ip.address.address,
              port: srv.port,
              type: tcp,
            );

            final alreadyAdded = results
                .where((element) => element.host == ip.address.address)
                .isNotEmpty;
            if (!alreadyAdded) {
              await device.initDeviceInfo();
              results.add(device);
            }
          }
        }
      }
    }

    client.stop();

    results.sort((a, b) => a.name!.compareTo(b.name!));
    return results;
  }
}
