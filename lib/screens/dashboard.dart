import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dashboard_tabs/home.dart';
import 'dashboard_tabs/profile.dart';
import 'dashboard_tabs/selling.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 1; // Default index (Home)
  late PageController _pageController;

  final Map<int, Widget> _screens = {}; // Lazy-loaded screens

  Widget _loadScreen(int index) {
    if (_screens.containsKey(index)) {
      return _screens[index]!;
    }

    switch (index) {
      case 0:
        _screens[index] = SellingScreen();
        break;
      case 1:
        _screens[index] = HomeScreen();
        break;
      case 2:
        _screens[index] = ProfileScreen();
        break;
    }

    return _screens[index]!;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);  // Move to the selected page
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);  // Initialize PageController
  }

  @override
  void dispose() {
    _pageController.dispose();  // Dispose PageController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _loadScreen(0),
          _loadScreen(1),
          _loadScreen(2),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Sell',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.edit, // Main FAB icon
        activeIcon: Icons.close, // Icon when FAB is expanded
        backgroundColor: Colors.tealAccent,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.monetization_on_outlined),
            label: 'Sell Now',
            backgroundColor: Colors.greenAccent,
            onTap: () {
              // Action for Add Image
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Image tapped')));
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.edit_note_outlined),
            label: 'Create Post',
            backgroundColor: Colors.greenAccent,
            onTap: () {
              // Action for Create Post
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Create Post tapped')));
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.message),
            label: 'Send Message',
            backgroundColor: Colors.greenAccent,
            onTap: () {
              // Action for Send Message
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Send Message tapped')));
            },
          ),
        ],
      ),
    );
  }
}
