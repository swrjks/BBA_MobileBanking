import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'observer.dart';
void main() {
  runApp(MyBankApp());
}

class MyBankApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dummy Bank App',
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF3B5EDF),
        scaffoldBackgroundColor: Color(0xFFF5F7FA),
        fontFamily: 'Roboto',
      ),
      home: LoginPage(),
    );
  }
}
