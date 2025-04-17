import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:validart/validart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PanelMobile extends StatefulWidget {
  const PanelMobile({super.key});

  @override
  State<PanelMobile> createState() => _PanelMobileState();
}

class _PanelMobileState extends State<PanelMobile> {

  bool enable = false;
  List<dynamic> peers = [];
  final TextEditingController name = TextEditingController();

  void initState(){
    super.initState();
    getPeers();
  }

  Future<void> getPeers() async {
    final response = await http.get(Uri.parse('http://192.168.209.136:3000/peers'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        peers = data['peers'];
      });
    } else {
      print('GET request failed with status: ${response.statusCode}');
    }
  }

  Future<void> addPeer() async {
    final validName = Validart().string().min(3);

    if(validName.validate(name.text)){
      final response = await http.post(
        Uri.parse('http://192.168.209.136:3000/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({ 'name': name.text }),
      );

      if (response.statusCode == 200) {
        name.text = '';
        final data = jsonDecode(response.body);
        print('POST Response: $data');
        getPeers();
      } else {
        print('POST request failed with status: ${response.statusCode}');
      }
    }
    else{
      callAlert('Invalid Name', 'A minimum of three characters is required for the name.');
    }
  }

  Future<void> removePeer(peer, ip) async {
    final response = await http.post(
      Uri.parse('http://192.168.209.136:3000/remove'),
      headers: {'Content-Type': 'application/json'},
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
      Uri.parse('http://192.168.209.136:3000/switch'),
      headers: {'Content-Type': 'application/json'},
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
      appBar: AppBar(title: Text('Connection Panel', style: GoogleFonts.poppins(color: Colors.white)), 
      backgroundColor: Colors.deepPurpleAccent, 
      automaticallyImplyLeading: false),
      body: Padding(padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      child: Column(
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
          Expanded(child: ListView.builder(
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
                  child: GestureDetector(child: Icon(Icons.qr_code, size: 35), onTap: (){})),
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
        ]))
    );
  }
}