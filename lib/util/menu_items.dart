import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter/material.dart';

class MenuItemData {
  final String to;
  final String label;
  final IconData icon;

  const MenuItemData({required this.to, required this.label, required this.icon});
}

const List<MenuItemData> menuItems = [
  MenuItemData(to: "dashboard", label: "Dashboard", icon: FeatherIcons.home),
  MenuItemData(to: "sales-report", label: "Sales Report", icon: FeatherIcons.trendingUp),
  MenuItemData(to: "tax-summary", label: "Tax Summary", icon: FeatherIcons.dollarSign),
  MenuItemData(to: "gst", label: "GST Billing", icon: FeatherIcons.clipboard),
  MenuItemData(to: "inventory", label: "Inventory", icon: FeatherIcons.box),
  MenuItemData(to: "profit", label: "Profit & Loss", icon: FeatherIcons.trendingUp),
  MenuItemData(to: "expenses", label: "Expenses", icon: FeatherIcons.dollarSign),
  MenuItemData(to: "customers", label: "Customers", icon: FeatherIcons.users),
  MenuItemData(to: "settings", label: "Settings", icon: FeatherIcons.settings),
];

const reportItem = MenuItemData(
  to: "reports",
  label: "Reports",
  icon: FeatherIcons.barChart2,
);
