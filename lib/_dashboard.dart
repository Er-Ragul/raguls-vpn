import 'package:flutter/material.dart';
import 'package:ragulsvpn/mobile/dashboard.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    final currentWidth = MediaQuery.of(context).size.width;
    //print('Current Width: ${currentWidth}');
    if(currentWidth < 820){
      return DashboardMobile();
    }
    else{
      return DashboardMobile();
    }
  }
}