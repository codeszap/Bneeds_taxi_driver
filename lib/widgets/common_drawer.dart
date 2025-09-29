import 'package:bneeds_taxi_driver/utils/storage.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';




class CommonDrawer extends ConsumerWidget {
  const CommonDrawer({super.key});

  Future<Map<String, String>> _loadSessionData() async {
    return {
      "username": SharedPrefsHelper.getDriverName().isNotEmpty
          ? SharedPrefsHelper.getDriverName()
          : "Guest",
      "mobileno": SharedPrefsHelper.getDriverMobile().isNotEmpty
          ? SharedPrefsHelper.getDriverMobile()
          : "N/A",
    };

  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(driverStatusProvider); // "OL", "OF", "RB"

    // --- Status colors ---
    Color bgColor;
    Color textColor;
    if (status == "OL") {
      bgColor = Colors.green;
      textColor = Colors.black;
    } else if (status == "RB") {
      bgColor = Colors.green;
      textColor = AppColors.buttonText;
    } else {
      bgColor = Colors.red;
      textColor = AppColors.buttonText;
    }

    return Drawer(
      child: Column(
        children: [
          FutureBuilder<Map<String, String>>(
            future: _loadSessionData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  color: bgColor,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.buttonText),
                  ),
                );
              }

              final user = snapshot.data!;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                color: bgColor,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.buttonText,
                          child: const Icon(Icons.person, size: 30, color: Colors.black),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user["username"]!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user["mobileno"]!,
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withOpacity(0.8),
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

          // Drawer Items
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: "Dashboard",
            onTap: () {
              Navigator.pop(context);
              context.push('/driverHome');
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
              context.push('/driverProfile');
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: textColor,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await SharedPrefsHelper.clearAll();

                if (context.mounted) {
                  final container = ProviderScope.containerOf(context);
                  container.invalidate(fetchProfileProvider);
                 context.go(AppRoutes.login);
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
      leading: Icon(icon, color: Colors.yellow.shade700),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      horizontalTitleGap: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      hoverColor: Colors.yellow.withOpacity(0.05),
    );
  }
}
