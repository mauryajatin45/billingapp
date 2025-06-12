import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:billingapp/util/menu_items.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback? onItemSelected;

  const Sidebar({Key? key, this.onItemSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top menu
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Osaka",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              ...menuItems.map((item) {
                return ListTile(
                  leading: Icon(item.icon, size: 22),
                  title: Text(item.label),
                  onTap: () {
                    context.go('/${item.to}');
                    if (onItemSelected != null) onItemSelected!();
                  },
                );
              }).toList(),
            ],
          ),

          // Bottom reports
          ListTile(
            leading: Icon(reportItem.icon, color: Colors.red),
            title: Text(reportItem.label, style: const TextStyle(color: Colors.red)),
            onTap: () {
              context.go('/${reportItem.to}');
              if (onItemSelected != null) onItemSelected!();
            },
          ),
        ],
      ),
    );
  }
}
