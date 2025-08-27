import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/common_textfield.dart';
import '../widgets/common_drawer.dart';
import '../models/user_profile_model.dart';
import '../providers/profile_provider.dart';
import 'package:go_router/go_router.dart';

final usernameProvider = StateProvider<String>((ref) => '');
final mobileProvider = StateProvider<String>((ref) => '');
final documentProvider = StateProvider<Map<String, File?>>((ref) => {});
class DriverProfileScreen extends ConsumerStatefulWidget {
  final bool isNewUser;

  const DriverProfileScreen({
    super.key,
    this.isNewUser = false,
  });

  @override
  ConsumerState<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentIndex = 0;
  late PageController _pageController;

  // Personal Info Controllers
  late TextEditingController nameController;
  late TextEditingController dobController;
  late TextEditingController address1Controller;
  late TextEditingController address2Controller;
  late TextEditingController address3Controller;
  late TextEditingController cityController;

  // Vehicle Info Controllers
  late TextEditingController vehicleModelController;
  late TextEditingController vehicleNumberController;
  late TextEditingController licenseNumberController;

  late ValueNotifier<String> genderValue;

  bool _isSaveEnabled = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final username = ref.read(usernameProvider);
    nameController = TextEditingController(text: username);
    dobController = TextEditingController();
    address1Controller = TextEditingController();
    address2Controller = TextEditingController();
    address3Controller = TextEditingController();
    cityController = TextEditingController();
    vehicleModelController = TextEditingController();
    vehicleNumberController = TextEditingController();
    licenseNumberController = TextEditingController();
    genderValue = ValueNotifier<String>("M");

    // Listeners to update save button state
    nameController.addListener(_updateButtonState);
    dobController.addListener(_updateButtonState);
    address1Controller.addListener(_updateButtonState);
    address2Controller.addListener(_updateButtonState);
    address3Controller.addListener(_updateButtonState);
    cityController.addListener(_updateButtonState);
    vehicleModelController.addListener(_updateButtonState);
    vehicleNumberController.addListener(_updateButtonState);
    licenseNumberController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      _isSaveEnabled = _isCurrentTabValid();
    });
  }

  bool _isCurrentTabValid() {
    switch (_currentIndex) {
      case 0: // Personal Tab
        return nameController.text.isNotEmpty &&
            dobController.text.isNotEmpty &&
            address1Controller.text.isNotEmpty &&
            cityController.text.isNotEmpty;
      case 1: // Vehicle Tab
        return vehicleModelController.text.isNotEmpty &&
            vehicleNumberController.text.isNotEmpty &&
            licenseNumberController.text.isNotEmpty;
      case 2: // Documents Tab
        return true; // or add validation if needed
      default:
        return false;
    }
  }

Future<void> _pickDocument(String key) async {
  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      ref.read(documentProvider.notifier).state = {
        ...ref.read(documentProvider),
        key: file,
      };
    }
  } catch (e) {
    debugPrint("Image Picker Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to pick image")),
    );
  }
}



  @override
  void dispose() {
    _pageController.dispose();
    nameController.dispose();
    dobController.dispose();
    address1Controller.dispose();
    address2Controller.dispose();
    address3Controller.dispose();
    cityController.dispose();
    vehicleModelController.dispose();
    vehicleNumberController.dispose();
    licenseNumberController.dispose();
    genderValue.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dobController.text = DateFormat("dd-MM-yyyy").format(picked);
      _updateButtonState();
    }
  }



  Future<void> _saveProfile() async {
    if (!_isCurrentTabValid()) return;

    final mobile = ref.read(mobileProvider);

    final profile = UserProfile(
      userid: "",
      userName: nameController.text,
      password: "",
      mobileNo: mobile,
      gender: genderValue.value,
      dob: dobController.text,
      address1: address1Controller.text,
      address2: address2Controller.text,
      address3: address3Controller.text,
      city: cityController.text,
    );

    try {
      // await ref.read(insertProfileProvider(profile).future);

      // Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print("Driver FCM Token: $fcmToken");

      // Save profile + token in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDriverProfileCompleted', true);
      await prefs.setString('driverName', nameController.text);
      await prefs.setString('driverMobile', mobile);
      await prefs.setString('driverCity', cityController.text);

      if (fcmToken != null) {
        await prefs.setString('driverFcmToken', fcmToken);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );

      // Navigate to home
      context.go('/driverHome');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    }
  }

  Widget _tabCard({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: child,
      ),
    );
  }

  Widget _personalTab() => _tabCard(
        child: Column(
          children: [
            CommonTextField(
              label: "Full Name",
              controller: nameController,
              prefixIcon: Icons.person,
              prefixIconColor: Colors.grey[600],
              fillColor: Colors.white,
              focusedBorderColor: Colors.blueGrey,
              enabledBorderColor: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String>(
              valueListenable: genderValue,
              builder: (context, value, _) {
                return DropdownButtonFormField<String>(
                  value: value,
                  items: const [
                    DropdownMenuItem(value: "M", child: Text("Male")),
                    DropdownMenuItem(value: "F", child: Text("Female")),
                    DropdownMenuItem(value: "O", child: Text("Other")),
                  ],
                  onChanged: (newVal) {
                    if (newVal != null) genderValue.value = newVal;
                    _updateButtonState();
                  },
                  decoration: InputDecoration(
                    labelText: "Gender",
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: Colors.grey[400]!, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Colors.blueGrey, width: 2),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: CommonTextField(
                  label: "Date of Birth",
                  controller: dobController,
                  prefixIcon: Icons.calendar_today,
                  prefixIconColor: Colors.grey[600],
                  fillColor: Colors.white,
                  focusedBorderColor: Colors.blueGrey,
                  enabledBorderColor: Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CommonTextField(
              label: "Address Line 1",
              controller: address1Controller,
              prefixIcon: Icons.home,
              prefixIconColor: Colors.grey[600],
              fillColor: Colors.white,
              focusedBorderColor: Colors.blueGrey,
              enabledBorderColor: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            CommonTextField(
              label: "Address Line 2",
              controller: address2Controller,
              prefixIcon: Icons.home,
              prefixIconColor: Colors.grey[600],
              fillColor: Colors.white,
              focusedBorderColor: Colors.blueGrey,
              enabledBorderColor: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            CommonTextField(
              label: "Address Line 3",
              controller: address3Controller,
              prefixIcon: Icons.home,
              prefixIconColor: Colors.grey[600],
              fillColor: Colors.white,
              focusedBorderColor: Colors.blueGrey,
              enabledBorderColor: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            CommonTextField(
              label: "City",
              controller: cityController,
              prefixIcon: Icons.location_city,
              prefixIconColor: Colors.grey[600],
              fillColor: Colors.white,
              focusedBorderColor: Colors.blueGrey,
              enabledBorderColor: Colors.grey[400],
            ),
          ],
        ),
      );

  Widget _vehicleTab() => _tabCard(
        child: Column(
          children: [
            CommonTextField(
              label: "Vehicle Model",
              controller: vehicleModelController,
              prefixIcon: Icons.directions_car,
              prefixIconColor: Colors.grey[600],
              fillColor: Colors.white,
              focusedBorderColor: Colors.blueGrey,
              enabledBorderColor: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            CommonTextField(
              label: "Vehicle Number",
              controller: vehicleNumberController,
              prefixIcon: Icons.confirmation_number,
              prefixIconColor: Colors.grey[600],
              fillColor: Colors.white,
              focusedBorderColor: Colors.blueGrey,
              enabledBorderColor: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            CommonTextField(
              label: "License Number",
              controller: licenseNumberController,
              prefixIcon: Icons.badge,
              prefixIconColor: Colors.grey[600],
              fillColor: Colors.white,
              focusedBorderColor: Colors.blueGrey,
              enabledBorderColor: Colors.grey[400],
            ),
          ],
        ),
      );

Widget _documentsTab() => _tabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upload Required Documents",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          _uploadTile("dl_front", "Driving License (Front)", Icons.badge),
          const SizedBox(height: 12),
          _uploadTile("dl_back", "Driving License (Back)", Icons.badge_outlined),

          const Divider(height: 32),

          _uploadTile("rc", "Vehicle RC", Icons.directions_car),
          const SizedBox(height: 12),
          _uploadTile("insurance", "Insurance Copy", Icons.policy),

          const Divider(height: 32),

          _uploadTile("aadhar", "Aadhar / ID Proof (Optional)", Icons.perm_identity),
        ],
      ),
    );

/// Small reusable widget for upload field
Widget _uploadTile(String key, String label, IconData icon) {
  final file = ref.watch(documentProvider)[key];

  return GestureDetector(
    onTap: () => _pickDocument(key),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          file == null
              ? const Icon(Icons.upload_file, color: Colors.blueGrey)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final tabs = [_personalTab(), _vehicleTab(), _documentsTab()];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      drawer: widget.isNewUser ? null : CommonDrawer(),
      appBar: AppBar(
        title: const Text(
          "Driver Profile",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(tabs.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentIndex == index ? 12 : 8,
                height: _currentIndex == index ? 12 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? const Color(0xFFFFD700)
                      : Colors.grey[400],
                ),
              );
            }),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _updateButtonState();
                });
              },
              children: tabs,
            ),
          ),
        ],
      ),
      // Stylish floating Save button
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GestureDetector(
            onTap: _isSaveEnabled ? _saveProfile : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: _isSaveEnabled
                    ? const Color(0xFFFFD700)
                    : Colors.grey[400],
                borderRadius: BorderRadius.circular(24),
                boxShadow: _isSaveEnabled
                    ? [
                        const BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.save, color: Colors.black87),
                  SizedBox(width: 8),
                  Text(
                    "Save Profile",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFFD700),
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Personal"),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car), label: "Vehicle"),
          BottomNavigationBarItem(
              icon: Icon(Icons.upload_file), label: "Documents"),
        ],
      ),
    );
  }
}
