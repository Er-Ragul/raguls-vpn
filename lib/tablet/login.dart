import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:validart/validart.dart';

class LoginTablet extends StatefulWidget {
  const LoginTablet({super.key});

  @override
  State<LoginTablet> createState() => _LoginTabletState();
}

class _LoginTabletState extends State<LoginTablet> {

  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  void loginUserAccount() async {
    final validEmail = Validart().string().email();
    final validPassword = Validart().string().min(8);

    if(validEmail.validate(email.text)){
      if(validPassword.validate(password.text)){
        try{

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
    else{
      callAlert('Invalid Email', 'Please enter valid email address !');
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