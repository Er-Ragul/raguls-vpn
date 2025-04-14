import 'package:flutter/material.dart';

class LoginTablet extends StatefulWidget {
  const LoginTablet({super.key});

  @override
  State<LoginTablet> createState() => _LoginTabletState();
}

class _LoginTabletState extends State<LoginTablet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(
        child: Text('Tablet Login Page'),
      )),
    );
  }
}