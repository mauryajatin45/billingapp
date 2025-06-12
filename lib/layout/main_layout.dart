import 'package:flutter/material.dart';
import 'package:billingapp/layout/sidebar.dart';
import 'package:billingapp/layout/top_navbar.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({Key? key, required this.child}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with SingleTickerProviderStateMixin {
  late final AnimationController _sidebarController;
  bool get isSidebarOpen => _sidebarController.value == 1;

  static const double sidebarWidth = 250;

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Sidebar is closed by default on app load, so controller starts at 0.
  }

  void toggleSidebar() {
    if (isSidebarOpen) {
      _sidebarController.reverse();
    } else {
      _sidebarController.forward();
    }
  }

  void closeSidebar() {
    if (isSidebarOpen) {
      _sidebarController.reverse();
    }
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: Stack(
        children: [
          // Main content + top navbar
          Column(
            children: [
              TopNavbar(onMenuPressed: isWideScreen ? null : toggleSidebar),
              Expanded(child: widget.child),
            ],
          ),

          // Sidebar on wide screens - permanently visible on left side, no overlay
          if (isWideScreen)
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              width: sidebarWidth,
              child: Sidebar(
                onItemSelected: null, // no need to close on wide screen
              ),
            ),

          // Sidebar overlay for small screens (animated)
          if (!isWideScreen)
            AnimatedBuilder(
              animation: _sidebarController,
              builder: (context, child) {
                double slide = sidebarWidth * _sidebarController.value;
                double backdropOpacity = 0.5 * _sidebarController.value;

                return Stack(
                  children: [
                    // Backdrop
                    _sidebarController.value > 0
                        ? GestureDetector(
                            onTap: closeSidebar,
                            child: Container(
                              color: Colors.black.withOpacity(backdropOpacity),
                            ),
                          )
                        : const SizedBox.shrink(),

                    // Sidebar sliding in from left
                    Transform.translate(
                      offset: Offset(-sidebarWidth + slide, 0),
                      child: SizedBox(
                        width: sidebarWidth,
                        height: MediaQuery.of(context).size.height,
                        child: Material(
                          elevation: 16,
                          child: Sidebar(
                            onItemSelected: closeSidebar,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
