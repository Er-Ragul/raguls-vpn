import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Loader extends StatefulWidget {
  const Loader({super.key});

  @override
  State<Loader> createState() => _LoaderState();
}

class _LoaderState extends State<Loader> {

  final storage = FlutterSecureStorage();

  void checkLogin() async {
    //await storage.deleteAll();
    String? result = await storage.read(key: 'user_data');

    if(result != null){
      Navigator.pushReplacementNamed(context, '/dashboard', arguments: result);
    }
    else{
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  void initState(){
    super.initState();
    //checkLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Container(
        width: double.infinity,
        color: Colors.deepPurpleAccent,
        child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("VPN", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 90)),
            Text("    A product of Ragul's Enterprise", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10)),
          ],
        )),
      )),
    );
  }
}