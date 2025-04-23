import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:validart/validart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SignupTablet extends StatefulWidget {
  const SignupTablet({super.key});

  @override
  State<SignupTablet> createState() => _SignupTabletState();
}

class _SignupTabletState extends State<SignupTablet> {

  final storage = FlutterSecureStorage();
  final TextEditingController endpoint = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController repassword = TextEditingController();

  void createUserAccount() async {

    final validEmail = Validart().string().email();
    final validPassword = Validart().string().min(8);
    bool isValidInput(String input) {
      final ipRegex = RegExp(r'^((25[0-5]|2[0-4]\d|1\d\d|\d{1,2})\.){3}'
                            r'(25[0-5]|2[0-4]\d|1\d\d|\d{1,2})(:\d{1,5})?$');
      final domainRegex = RegExp(r'^(?!\-)([a-zA-Z0-9\-]{1,63}\.)+[a-zA-Z]{2,}$');
      return ipRegex.hasMatch(input) || domainRegex.hasMatch(input);
    }

    if(isValidInput(endpoint.text)){
      if(validEmail.validate(email.text)){
        if(validPassword.validate(password.text)){
          if(password.text == repassword.text){
            try{
              final response = await http.post(
                Uri.parse('http://${endpoint.text}/signup'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({ 'email': email.text, 'password': password.text })
              );

              if(response.statusCode == 200) {
                final received = jsonDecode(response.body);

                Map<String, dynamic> user = {
                  'uid': received['uid'],
                  'endpoint': '${endpoint.text}',
                  'token': null
                };

                String result = jsonEncode(user);
                await storage.write(key: 'user_data', value: result);    
                
                Navigator.pushReplacementNamed(context, '/login');
              } 
              else{
                print('POST request failed with status: ${response.statusCode}');
              }
            }
            catch(err){
              print(err);
            }
          }
          else{
            callAlert('Password Mismatch', 'Password is not matching');
          }
        }
        else{
          callAlert('Invalid Password', 'Password should not be less than 8 characters');
        }
      }
      else{
        callAlert('Invalid Email', 'Please enter valid email address !');
      }
    }
    else{
      callAlert('Invalid Address', 'Please enter valid server IP or FQDN !');
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
                      Text('Signup', style: GoogleFonts.poppins(color: Colors.deepPurpleAccent, fontSize: 30, fontWeight: FontWeight.bold))
                    ]),
                    SizedBox(height: 40),
                    // VPN logo
                    Image.asset('assets/vpn.png', width: 120),
                    SizedBox(height: 40),
                    // Link inputbox
                    TextField(
                      controller: endpoint,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        labelText: 'Server IP (or) FQDN',
                        icon: Icon(Icons.link, color: Colors.deepPurpleAccent)
                      ),
                    ),
                    SizedBox(height: 20),
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
                    SizedBox(height: 20),
                    // Password inputbox
                    TextField(
                      controller: repassword,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Re-enter password',
                        icon: Icon(Icons.password, color: Colors.deepPurpleAccent)
                      ),
                    ),
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      // Login button
                      ElevatedButton.icon(onPressed: (){
                        createUserAccount();
                      }, 
                      icon: Text('Create Account', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
                      label: Icon(Icons.account_box, color: Colors.white, size: 25),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)
                        )
                      ))
                    ]),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Text("Already have an account? ", style: GoogleFonts.poppins()),
                      GestureDetector(
                        onTap: (){
                          Navigator.pushNamed(context, '/');
                        },
                        child: Text('Login In', style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold)))
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