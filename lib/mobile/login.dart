import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginMobile extends StatefulWidget {
  const LoginMobile({super.key});

  @override
  State<LoginMobile> createState() => _LoginMobileState();
}

class _LoginMobileState extends State<LoginMobile> {

  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Safearea & Container widget
      body: SafeArea(child: Container(
        width: double.infinity,
        color: Colors.deepPurpleAccent,
        // Column
        child: Column(
          // Row
          children: [
            Row(
              children: [
              Padding(padding: EdgeInsets.fromLTRB(10, 35, 0, 0), child: Text(
                "Ragul's VPN", style: GoogleFonts.poppins(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)
              ))
            ]),
            Row(
              children: [
              Padding(padding: EdgeInsets.fromLTRB(10, 10, 0, 50), child: Text(
                "Equipped with WireGuard", style: GoogleFonts.poppins(color: Colors.white)
              ))
            ]),
            // Expanded & Container
            Expanded(child: Container(
              color: Colors.white,
              child: Center(
                child: Padding(padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: SingleChildScrollView( // SingleChildScrollView for smooth scroll
                  physics: BouncingScrollPhysics(),
                  // Column
                  child: Column(
                    children: [
                    // Title
                    Row(children: [
                      Text('Login', style: GoogleFonts.poppins(color: Colors.deepPurpleAccent, fontSize: 30, fontWeight: FontWeight.bold))
                    ]),
                    SizedBox(height: 40),
                    // VPN logo
                    Image.asset('assets/vpn.png', width: 120),
                    SizedBox(height: 40),
                    // Email inputbox
                    TextField(
                      controller: email,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        icon: Icon(Icons.email, color: Colors.deepPurpleAccent)
                      ),
                    ),
                    SizedBox(height: 20),
                    // Password inputbox
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        icon: Icon(Icons.password, color: Colors.deepPurpleAccent)
                      ),
                    ),
                    // SizedBox
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      // Login button
                      ElevatedButton.icon(onPressed: (){
                        
                      }, 
                      icon: Text('Login', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
                      label: Icon(Icons.login, color: Colors.white, size: 25),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)
                        )
                      )),
                      Text('    or    ', style: GoogleFonts.poppins()),
                      // Direct VPN access button
                      ElevatedButton.icon(onPressed: (){

                      }, 
                      icon: Text('Access VPN', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
                      label: Icon(Icons.vpn_key, color: Colors.white, size: 25),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)
                        )
                      ))
                    ],),
                    // SizedBox
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Text("Don't have an account? ", style: GoogleFonts.poppins()),
                      // Gesture detector
                      GestureDetector(
                        onTap: (){
                 
                        },
                        child: Text('Sign Up', style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold)))
                    ])
                  ],
                  ),
                )),
              ),
            ))
          ],
        ),
      )),
    );
  }
}