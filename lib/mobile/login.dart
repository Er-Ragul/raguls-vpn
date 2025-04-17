import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:validart/validart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class LoginMobile extends StatefulWidget {
  const LoginMobile({super.key});

  @override
  State<LoginMobile> createState() => _LoginMobileState();
}

class _LoginMobileState extends State<LoginMobile> {

  final storage = FlutterSecureStorage();
  final TextEditingController password = TextEditingController();

  void loginUserAccount() async {
    final validPassword = Validart().string().min(8);

    if(validPassword.validate(password.text)){
      try{
        String? result = await storage.read(key: 'user_data');

        if(result != null){
          final Map<String, dynamic> userData = jsonDecode(result);

          final response = await http.post(
            Uri.parse('http://192.168.209.136:3000/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({ 'email': userData['email'], 'password': password.text })
          );

          if(response.statusCode == 200) {
            final data = jsonDecode(response.body);

            Map<String, dynamic> user = {
              'uid': '${data['uid']}',
              'endpoint': '${userData['endpoint']}',
              'email': '${userData['email']}'
            };

            String result = jsonEncode(user);
            await storage.write(key: 'user_data', value: result);    
            
            Navigator.pushReplacementNamed(context, '/dashboard');
          } 
          else{
            print('POST request failed with status: ${response.statusCode}');
          }
        }
        //Navigator.pushReplacementNamed(context, '/dashboard');
      }
      catch(err){
        print(err);
      }
    }
    else{
      callAlert('Invalid Password', 'Password should not be less than 8 characters');
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
        color: Colors.deepPurpleAccent,
        child: Column(
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
            Expanded(child: Container(
              color: Colors.white,
              child: Center(
                child: Padding(padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
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
                    // Password inputbox
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        icon: Icon(Icons.password, color: Colors.deepPurpleAccent)
                      ),
                    ),
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      // Login button
                      ElevatedButton.icon(onPressed: (){
                        loginUserAccount();
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
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Text("Don't have an account? ", style: GoogleFonts.poppins()),
                      GestureDetector(
                        onTap: (){
                          Navigator.pushNamed(context, '/signup');
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