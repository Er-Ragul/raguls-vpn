import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class Loader extends StatefulWidget {
  const Loader({super.key});

  @override
  State<Loader> createState() => _LoaderState();
}

class _LoaderState extends State<Loader> {

  final storage = FlutterSecureStorage();

  Future<void> checkLogin() async {
    String? result = await storage.read(key: 'user_data');

    if(result != null){
      final Map<String, dynamic> userData = jsonDecode(result);
      final response = await http.get(Uri.parse('http://${userData['endpoint']}/auth'), 
        headers: {'Authorization': 'Bearer ${userData['token']}'}
      );

      if (response.statusCode == 200) {
        print('getToken ${userData['token']}');
        Navigator.pushReplacementNamed(context, '/dashboard', arguments: {'token': userData['token'], 'endpoint': userData['endpoint']}); 
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
    else{
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void initState(){
    super.initState();
    checkLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Container(
        width: double.infinity,
        color: Colors.white,
        child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/splashicon.png', width: 280),
            Text("Ragul's VPN", style: GoogleFonts.poppins(fontSize: 32, color: Colors.deepPurpleAccent)),
            SizedBox(height: 15),
            Text("A Self Manageable Custom VPN Solution", style: GoogleFonts.poppins(color: Colors.deepPurpleAccent),)
          ],
        )),
      )),
    );
  }
}