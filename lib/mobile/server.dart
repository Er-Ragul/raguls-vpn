import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServerMobile extends StatefulWidget {
  const ServerMobile({super.key});

  @override
  State<ServerMobile> createState() => _ServerMobileState();
}

class _ServerMobileState extends State<ServerMobile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(
        child: Text('Under Construction', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
      )),
    );
  }
}