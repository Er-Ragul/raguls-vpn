import 'package:flutter/material.dart';
import 'package:ragulsvpn/mobile/signup.dart';
import 'package:ragulsvpn/tablet/signup.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  @override
  Widget build(BuildContext context) {
    final currentWidth = MediaQuery.of(context).size.width;
    print('Current Width: ${currentWidth}');
    if(currentWidth <= 820){
      return SignupMobile();
    }
    else{
      return SignupTablet();
    }
  }
}

//    id("org.jetbrains.kotlin.android") version "1.8.22" apply false