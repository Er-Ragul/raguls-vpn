import 'package:flutter/material.dart';
import 'package:ragulsvpn/mobile/vpn.dart';
import 'package:ragulsvpn/mobile/panel.dart';
import 'package:ragulsvpn/mobile/settings.dart';

class DashboardMobile extends StatefulWidget {
  const DashboardMobile({super.key});

  @override
  State<DashboardMobile> createState() => _DashboardMobileState();
}

class _DashboardMobileState extends State<DashboardMobile> {

  int _currentIndex = 0;

  List<Widget> body = const [
    VpnMobile(),
    PanelMobile(),
    SettingsMobile()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.deepPurpleAccent,
        currentIndex: _currentIndex,
        onTap: (int index){
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            label: 'VPN',
            icon: Icon(Icons.vpn_key),
          ),
          BottomNavigationBarItem(
            label: 'Panel',
            icon: Icon(Icons.dashboard)
          ),
          BottomNavigationBarItem(
            label: 'Settings',
            icon: Icon(Icons.settings)
          ),
        ],
      ),
    );
  }
}