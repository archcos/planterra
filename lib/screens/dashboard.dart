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

  Future<Widget> _loadScreen(int index) async {
    if (_screens.containsKey(index)) {
      // If the screen is already loaded, return it.
      return _screens[index]!;
    }

    // Lazy load the screen based on index.
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
      body: FutureBuilder(
        future: _loadScreen(_selectedIndex),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Loading indicator
          } else if (snapshot.hasData) {
            return snapshot.data as Widget;
          } else {
            return const Center(child: Text('Error loading tab'));
          }
        },
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
