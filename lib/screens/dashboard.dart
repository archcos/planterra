import 'package:flutter/material.dart';
import 'package:planterra/screens/dashboard_tabs/home.dart';
import 'dashboard_tabs/profile.dart';
import 'dashboard_tabs/selling.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 1; // Default index (Home)

  // This will store the screens lazily.
  final Map<int, Widget> _screens = {};

  // Function to load the screen lazily
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex, // Maintains the current screen without refreshing
        children: [
          _loadScreen(0), // Selling screen
          _loadScreen(1), // Home screen
          _loadScreen(2), // Profile screen
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
    );
  }
}
