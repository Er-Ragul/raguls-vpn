import 'package:flutter/material.dart';
import 'package:ragulsvpn/loader.dart';
import 'package:ragulsvpn/_login.dart';
import 'package:ragulsvpn/_signup.dart';
import 'package:ragulsvpn/_dashboard.dart';

void main(){
  runApp(MaterialApp(
    initialRoute: "/",
    routes: {
      "/": (context) => Login(),
      "/loader": (context) => Loader(),
      "/signup": (context) => Signup(),
      "/dashboard": (context) => Dashboard()
    },
  ));
}