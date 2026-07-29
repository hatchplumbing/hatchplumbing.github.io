import 'package:flutter/material.dart';
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Settings'),
      ), 
      body:
       Column(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () {
              // Navigate to profile settings
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            onTap: () {
              // Navigate to notification settings
            },
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Privacy'),
            onTap: () {
              // Navigate to privacy settings
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
            onTap: () {
              // Navigate to help and support
            },
          ),
        ],
      
      ),
    );
  }
}