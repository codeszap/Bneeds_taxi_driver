import 'package:bneeds_taxi_driver/providers/profile_provider.dart';
import 'package:bneeds_taxi_driver/screens/ProfileScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonDrawer extends StatelessWidget {
  const CommonDrawer({super.key});

  Future<Map<String, String>> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "username": prefs.getString('username') ?? "Guest",
      "mobileno": prefs.getString('mobileno') ?? "N/A",
    };
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          FutureBuilder<Map<String, String>>(
            future: _loadSessionData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.deepPurple,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }

              final user = snapshot.data!;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                color: Colors.deepPurple,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.deepPurple.shade50,
                          child: const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user["username"]!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user["mobileno"]!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),

          // ✅ Rest of drawer items
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: "Dashboard",
            onTap: () {
              Navigator.pop(context);
              context.push('/home');
            },
          ),
          _buildDrawerItem(
            icon: Icons.help_outline,
            title: "Help",
            onTap: () {
              Navigator.pop(context);
              context.push('/customer-support');
            },
          ),
          _buildDrawerItem(
            icon: Icons.history,
            title: "My Rides",
            onTap: () {
              Navigator.pop(context);
              context.push('/my-rides');
            },
          ),
          _buildDrawerItem(
            icon: Icons.person_outline,
            title: "Profile",
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          _buildDrawerItem(
            icon: Icons.wallet,
            title: "Wallet",
            onTap: () {
              Navigator.pop(context);
              context.push('/wallet');
            },
          ),

          const Spacer(),

          // ✅ Logout button same as before
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (context.mounted) {
                  final container = ProviderScope.containerOf(context);
                //  container.invalidate(credentialsProvider);
                  container.invalidate(fetchProfileProvider);
                  context.go('/login');
                }
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      horizontalTitleGap: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      hoverColor: Colors.deepPurple.withOpacity(0.05),
    );
  }
}
