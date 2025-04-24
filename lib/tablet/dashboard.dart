import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:validart/validart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DashboardTablet extends StatefulWidget {
  const DashboardTablet({super.key});

  @override
  State<DashboardTablet> createState() => _DashboardTabletState();
}

class _DashboardTabletState extends State<DashboardTablet> {

  final wireguard = WireGuardFlutter.instance;
  String configuration = '';
  String serverIP = '';
  bool power = false;
  bool isConfig = false;
  bool isLoading = true;
  String endpoint = '';
  String token = '';
  List<dynamic> peers = [];

  final TextEditingController name = TextEditingController();
  final storage = FlutterSecureStorage();

  @override
  void initState(){
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if(args != null){
        token = args['token'];
        endpoint = args['endpoint'];
        getPeers();
      }
    });
  }

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
          providerBundleIdentifier: 'com.raguls.vpn',
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

  Future<void> activateServer() async {
    final response = await http.post(Uri.parse('http://${endpoint}/init'), 
      headers: {
        'Authorization': 'Bearer ${token}',
        'Content-Type': 'application/json'  
      },
      body: jsonEncode({ 'type': 'init', 'name': 'Server', 'ip': '10.0.0.1' })
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      simpleNotification('VPN Server Started Successfully');
    } else {
      callAlert('Already Running', 'Server already running');
      print('GET request failed with status: ${response.statusCode}');
    }
  }

  Future<void> resetServer() async {
    final response = await http.get(Uri.parse('http://${endpoint}/reset'), 
      headers: {'Authorization': 'Bearer ${token}'}
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      getPeers();
      simpleNotification('VPN Server Reset Successful');
    } else {
      callAlert('Incative', 'Server not running');
      print('GET request failed with status: ${response.statusCode}');
    }
  }

  Future<void> logoutUser() async {
    //await storage.delete(key: 'user_data');
    String? result = await storage.read(key: 'user_data');

    if(result != null){
      final Map<String, dynamic> userData = jsonDecode(result);

      Map<String, dynamic> user = {
        'uid': userData['uid'],
        'endpoint': userData['endpoint'],
        'token': null
      };

      String modified = jsonEncode(user);
      await storage.write(key: 'user_data', value: modified); 

      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> getPeers() async {
    try{
      final response = await http.get(Uri.parse('http://${endpoint}/peers'), 
        headers: {'Authorization': 'Bearer ${token}'}
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          peers = data['peers'];
          isLoading = false;
        });
      } else {
        //callAlert('Server Inactive', 'The server may not have started. Please start it from the settings.');
        print('GET request failed with status: ${response.statusCode}');
      }
    }
    catch(err){
      print(err);
    }
  }

  Future<void> addPeer() async {
    final validName = Validart().string().min(3);

    if(validName.validate(name.text)){
      final response = await http.post(
        Uri.parse('http://${endpoint}/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({ 'type': 'add', 'name': name.text }),
      );

      if (response.statusCode == 200) {
        name.text = '';
        final data = jsonDecode(response.body);
        print('POST Response: $data');
        getPeers();
      } else {
        callAlert('Server Error', 'Server might be down. Please check and try again.');
      }
    }
    else{
      callAlert('Invalid Name', 'A minimum of three characters is required for the name.');
    }
  }

  Future<void> removePeer(peer, ip) async {
    final response = await http.post(
      Uri.parse('http://${endpoint}/remove'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({ 'peer': peer, 'ip': ip }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('POST Response: $data');
      getPeers();
    } else {
      print('POST request failed with status: ${response.statusCode}');
    }
  }

  Future<void> switchPeer(ip, peer, cmd) async {
    final response = await http.post(
      Uri.parse('http://${endpoint}/switch'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'  
      },
      body: jsonEncode({ 'ip': ip, 'peer': peer, 'cmd': cmd }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('POST Response: $data');
      getPeers();
    } else {
      print('POST request failed with status: ${response.statusCode}');
    }
  }

  Future<void> displayQrcode(address) async {

    final response = await http.post(
      Uri.parse('http://${endpoint}/qr'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'  
      },
      body: jsonEncode({ 'ip': address }),
    );

    if (response.statusCode == 200) {
      final received = jsonDecode(response.body);
      final String base64Str = received['qr'];

      final String cleanedBase64 = base64Str.contains(',')
          ? base64Str.split(',')[1]
          : base64Str;

      Uint8List imageBytes = base64Decode(cleanedBase64);

      showModalBottomSheet(context: context, builder: (context){
        return Container(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Scan QR'),
              Image.memory(imageBytes),
              ElevatedButton(onPressed: (){
                Navigator.pop(context);
              }, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: Text('Close', style: GoogleFonts.poppins(color: Colors.white)))
            ],
          )
        );
      });

    } else {
      print('POST request failed with status: ${response.statusCode}');
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

  void simpleNotification(message){
    final snackBar = SnackBar(
    content: Text(message),
    duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(child: Row(
        children: [
          // Left side
          Expanded(child: Column(
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
            Text(isConfig ? 'Server configuration has been detected' : 'Server configuration was not detected.', style: GoogleFonts.poppins(color: isConfig == true ? Colors.greenAccent : Colors.redAccent)),
            SizedBox(height: 40),
            Divider(height: 0),
            SizedBox(height: 40),
            // Settings list
            Text('Settings', style: GoogleFonts.poppins(fontSize: 30, color: Colors.deepPurpleAccent)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  ListTile(
                    leading: Icon(Icons.power_settings_new),
                    title: Text('Activate'),
                    onTap: (){
                      activateServer();
                    },
                  ),
                  Divider(height: 0),
                  ListTile(
                    leading: Icon(Icons.restart_alt),
                    title: Text('Hard Reset'),
                    onTap: (){
                      resetServer();
                    },
                  ),
                  Divider(height: 0),
                  ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Password Reset'),
                    onTap: (){
                      simpleNotification('This feature will be activated in the next update.');
                    },
                  ),
                  Divider(height: 0),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Logout'),
                    onTap: (){
                      logoutUser();
                    },
                  ),
                  Divider(height: 0),
                ],
              ))
            ],
          )),
          // Right side
          Expanded(child: Column(
            children: [
              // Add connections
              Row(children: [
                Expanded(child: TextField(
                  controller: name,
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Add Peer'),
                )),
                Padding(padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                child: ElevatedButton.icon(onPressed: (){
                  addPeer();
                }, 
                label: Icon(Icons.add, size: 30), 
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  )
                )))
              ]),
              // List of connections
              SizedBox(height: 15),
              Expanded(child: isLoading ? Center(child: CircularProgressIndicator()):  
                ListView.builder(
                itemCount: peers.length,
                itemBuilder: (context, index){
                  return Card(child: Row(
                    children: [
                      Expanded(child: ListTile(
                        leading: Icon(Icons.link_sharp),
                        title: Text('${peers[index]['name']}', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
                        subtitle: Text('IP: ${peers[index]['ip']}', style: GoogleFonts.poppins(color: Colors.black)),
                      )),
                      // Delete connection
                      Padding(padding: EdgeInsets.all(8),
                      child: GestureDetector(child: Icon(Icons.delete, size: 35), onTap: (){
                        removePeer(peers[index]['public'], peers[index]['ip']);
                      })),
                      // Scan QR
                      Padding(padding: EdgeInsets.all(8),
                      child: GestureDetector(child: Icon(Icons.qr_code, size: 35), onTap: (){
                        displayQrcode(peers[index]['ip']);
                      })),
                      // On/Off connection
                      Padding(padding: EdgeInsets.all(8),
                      child: Switch(value: peers[index]['enabled'], 
                      onChanged: (bool value){
                        switchPeer(peers[index]['ip'], peers[index]['public'], !peers[index]['enabled']);
                      },
                      activeColor: Colors.deepPurpleAccent)),
                    ],
                  ));
                }
              ))
            ],
          ))
        ],
      )),
    );
  }
}