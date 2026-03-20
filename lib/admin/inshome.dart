import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:LaaLingo/admin/callbbox.dart';
import 'package:LaaLingo/admin/insmail.dart';
import 'package:LaaLingo/admin/inssettings.dart';
import 'package:LaaLingo/screens/login_page.dart';

class InsHome extends StatefulWidget {
  late ColorScheme dync;
  InsHome({required this.dync, super.key});

  @override
  State<InsHome> createState() => _InsHomeState();
}

class _InsHomeState extends State<InsHome> {
  int _selectedIndex = 0;

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 1:
        return InsMailPage(dync: widget.dync);
      case 2:
        return InsSettingsPage(dync: widget.dync);
      case 0:
      default:
        return callbox(dync: widget.dync);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.dync.primary,
      appBar: AppBar(
        backgroundColor: widget.dync.primary,
        foregroundColor: widget.dync.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => LoginPage(dync: widget.dync),
              ),
              (route) => false,
            );
          },
        ),
        title: const Text('Instructor Panel'),
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: widget.dync.inversePrimary,
            borderRadius: BorderRadius.all(Radius.circular(20))),
        child: GNav(
          selectedIndex: _selectedIndex,
          duration: Duration(milliseconds: 1000),
          tabBorderRadius: 20,
          tabMargin: EdgeInsets.all(3),
          color: widget.dync.primary,
          tabBackgroundColor: widget.dync.primary,
          activeColor: Colors.white,
          backgroundColor: widget.dync.inversePrimary,
          tabs: [
            GButton(
              icon: Icons.home,
            ),
            GButton(icon: Icons.mail),
            GButton(
              icon: Icons.settings,
            ),
          ],
          onTabChange: (value) {
            setState(() {
              _selectedIndex = value;
            });
          },
        ),
      ),
      body: _buildBody(),
    );
  }
}
