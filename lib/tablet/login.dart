import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:validart/validart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class LoginTablet extends StatefulWidget {
  const LoginTablet({super.key});

  @override
  State<LoginTablet> createState() => _LoginTabletState();
}

class _LoginTabletState extends State<LoginTablet> {

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
            Uri.parse('http://${userData['endpoint']}/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({ 'uid': userData['uid'], 'password': password.text })
          );

          if(response.statusCode == 200) {
            final received = jsonDecode(response.body);

            Map<String, dynamic> user = {
              'uid': userData['uid'],
              'endpoint': userData['endpoint'],
              'token': received['token']
            };

            String result = jsonEncode(user);
            await storage.write(key: 'user_data', value: result);    
            print('getToken ${received['token']}');
            
            Navigator.pushReplacementNamed(context, '/dashboard', arguments: {'token': received['token'], 'endpoint': userData['endpoint']});
          } 
          else{
            callAlert('Invalid Password', 'Invalid password or user may not exist');
            print('POST request failed with status: ${response.statusCode}');
          }
        }
        else{
          callAlert('Invalid Password', 'Invalid password or user may not exist');
        }
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
              Expanded(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(children: [
                      Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 0), child: Text(
                        "Ragul's VPN", style: GoogleFonts.poppins(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold)
                      )),
                      Padding(padding: EdgeInsets.fromLTRB(0, 14, 0, 50), child: Text(
                        "Equipped with WireGuard", style: GoogleFonts.poppins(color: Colors.white, fontSize: 20)
                      ))
                    ])
                ])
              ])),
              Expanded(child: Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
                child: Padding(padding: EdgeInsets.symmetric(horizontal: 40),
                child: Center(
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
                  ))),)
              ))
          ],
        )
      )),
    );
  }
}