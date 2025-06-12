import 'package:flutter/material.dart';

class TopNavbar extends StatelessWidget {
  final VoidCallback? onMenuPressed; // Nullable here

  const TopNavbar({Key? key, this.onMenuPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Billing App"),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed, // works fine if null
      ),
      elevation: 0,
      backgroundColor: Colors.blueGrey.shade900,
      foregroundColor: Colors.white,
    );
  }
}
