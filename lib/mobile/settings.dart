import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsMobile extends StatefulWidget {
  const SettingsMobile({super.key});

  @override
  State<SettingsMobile> createState() => _SettingsMobileState();
}

class _SettingsMobileState extends State<SettingsMobile> {

  String endpoint = '';
  String token = '';
  final storage = FlutterSecureStorage();

  @override
  void initState(){
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if(args != null){
        token = args['token'];
        endpoint = args['endpoint'];
      }
    });
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
    } else {
      callAlert('Incative', 'Server not running');
      print('GET request failed with status: ${response.statusCode}');
    }
  }

  Future<void> logoutUser() async {
    await storage.delete(key: 'user_data');
    Navigator.pushReplacementNamed(context, '/login');
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
      appBar: AppBar(title: Text('Settings', style: GoogleFonts.poppins(color: Colors.white)), 
      backgroundColor: Colors.deepPurpleAccent, 
      automaticallyImplyLeading: false),
      body: SafeArea(child: Center(
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
                print('Password Reset clicked');
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
        )
      )),
    );
  }
}