import 'package:flutter/material.dart';
import 'package:ragulsvpn/mobile/login.dart';
import 'package:ragulsvpn/tablet/login.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  @override
  Widget build(BuildContext context) {
    final currentWidth = MediaQuery.of(context).size.width;
    print('Current Width: ${currentWidth}');
    if(currentWidth < 820){
      return LoginMobile();
    }
    else{
      return LoginTablet();
    }
  }
}