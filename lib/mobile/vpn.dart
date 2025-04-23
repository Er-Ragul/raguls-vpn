import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';

class VpnMobile extends StatefulWidget {
  const VpnMobile({super.key});

  @override
  State<VpnMobile> createState() => _VpnMobileState();
}

class _VpnMobileState extends State<VpnMobile> {

  final wireguard = WireGuardFlutter.instance;
  String configuration = '';
  String serverIP = '';
  bool power = false;
  bool isConfig = false;

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: true
  );

  void updateServerIP(){
      final regex = RegExp(r'Endpoint\s*=\s*(\S+)');
      final match = regex.firstMatch(configuration);

      if (match != null) {
        setState((){
          serverIP = match.group(1)!;
          isConfig = true;
        });
        print('Endpoint latest ${serverIP}');
      } else {
        print('Endpoint not found.');
      }
  }

  Future<void> checkForConnection() async {
    if(isConfig){
      if(!power){
        await wireguard.initialize(interfaceName: 'wg0');

        await wireguard.startVpn(
          serverAddress: serverIP,
          wgQuickConfig: configuration,
          providerBundleIdentifier: 'com.example.ragulsvpn',
        );

        final stage = await wireguard.stage();
        print('stage ${stage.runtimeType}');
        setState(() {
          power = !power;
        });
      }
      else{
        await wireguard.stopVpn();
        final stage = await wireguard.stage();
        print('stage ${stage}');
        setState(() {
          power = !power;
        });
      }
    }
    else {
      callAlert('No Configuration', 'Server config missing. Scan QR to load.');
    }
  }

  void callAlert(String title, String content){
    showDialog(context: context, builder: (context) => AlertDialog(
      actions: [
        TextButton(onPressed: (){
          Navigator.of(context).pop();
        }, child: Text('Close'))
      ],
      //title: Text(title),
      contentPadding: EdgeInsets.all(20),
      content: Text(content),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Container(
        width: double.infinity,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("VPN ${power ? "Connected" : "Disconnected"}", style: GoogleFonts.poppins(fontSize: 30, color: Colors.deepPurpleAccent)),
            SizedBox(height: 40),
            // Button to connect with server
            ElevatedButton.icon(onPressed: (){
              checkForConnection();
            }, 
            label: power == false ? Icon(Icons.flash_off, color: Colors.white, size: 80) : Icon(Icons.flash_on, color: Colors.white, size: 80),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              padding: EdgeInsets.all(30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5)
              )
            )),
            SizedBox(height: 60),
            // Button to scan qr
            ElevatedButton.icon(onPressed: (){
              showModalBottomSheet(context: context, builder: (context){
                return Container(
                  padding: EdgeInsets.all(40),
                  child: MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      setState(() {
                        configuration = barcode.rawValue!;
                      });
                      Navigator.pop(context);
                    }
                    updateServerIP();
                  },
                ));
              });
            },
            label: Text('Scan QR'),
            icon: Icon(Icons.qr_code)),
            SizedBox(height: 40),
            //Server configuration has been detected.
            Text(isConfig ? 'Server configuration has been detected' : 'Server configuration was not detected.', style: GoogleFonts.poppins(color: isConfig == true ? Colors.greenAccent : Colors.redAccent))
          ],
        )
      )),
    );
  }
}