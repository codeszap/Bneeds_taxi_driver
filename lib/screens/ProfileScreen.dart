import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';


final documentProvider = StateProvider<Map<String, File?>>((ref) => {});

class DriverProfileScreen extends ConsumerStatefulWidget {
  final bool isNewUser;

  const DriverProfileScreen({super.key, this.isNewUser = false});

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
  late TextEditingController mobNoController;
  late TextEditingController dobController;
  late TextEditingController address1Controller;
  late TextEditingController address2Controller;
  late TextEditingController address3Controller;
  late TextEditingController cityController;

  // Vehicle Info Controllers
  late TextEditingController vehicleModelController;
  late TextEditingController vehicleNumberController;
  late TextEditingController licenseNumberController;
  late TextEditingController aadhaarNumberController;
  late TextEditingController fcdateController;
  late TextEditingController insdateController;

  late ValueNotifier<String> genderValue;

  bool _isSaveEnabled = false;

  final selectedVehicleTypeProvider = StateProvider<int?>((ref) => null);
  final selectedVehicleSubTypeProvider = StateProvider<int?>((ref) => null);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize controllers
    nameController = TextEditingController();
    mobNoController = TextEditingController();
    dobController = TextEditingController();
    address1Controller = TextEditingController();
    address2Controller = TextEditingController();
    address3Controller = TextEditingController();
    cityController = TextEditingController();
    vehicleModelController = TextEditingController();
    vehicleNumberController = TextEditingController();
    licenseNumberController = TextEditingController();
    aadhaarNumberController = TextEditingController();
    fcdateController = TextEditingController();
    insdateController = TextEditingController();
    genderValue = ValueNotifier<String>("M");

    // Add listeners
    _addFieldListeners();

    if (widget.isNewUser) {
      _prefillNewUserFields();
    } else {
      _loadExistingUserProfile();
    }
  }

  void _addFieldListeners() {
    final controllers = [
      nameController,
      mobNoController,
      dobController,
      address1Controller,
      address2Controller,
      address3Controller,
      cityController,
      vehicleModelController,
      vehicleNumberController,
      licenseNumberController,
      fcdateController,
      insdateController,
    ];

    for (var ctrl in controllers) {
      ctrl.addListener(_updateButtonState);
    }
  }

  void _prefillNewUserFields() {
    final username = ref.read(usernameProvider);
    final mobile = ref.read(mobileProvider);

    nameController.text = username;
    mobNoController.text = mobile;
  }

  String formatDate(String dateStr) {
    if (dateStr.isEmpty) return "";
    try {
      final parsed = DateFormat("M/d/yyyy h:mm:ss a").parse(dateStr);
      return DateFormat("dd-MM-yyyy").format(parsed);
    } catch (e) {
      return "";
    }
  }


  Future<void> _loadExistingUserProfile() async {
    final mobile = SharedPrefsHelper.getDriverMobile();

    if (mobile.isEmpty) return;

    mobNoController.text = mobile;

    try {
      final profileList = await ProfileRepository().getRiderLogin(mobileno: mobile);

      if (profileList.isEmpty) return;

      final profile = profileList.first;

      setState(() {
        nameController.text = profile.riderName;
        dobController.text = formatDate(profile.dateOfBirth);
        address1Controller.text = profile.add1;
        address2Controller.text = profile.add2;
        address3Controller.text = profile.add3;
        cityController.text = profile.city;
        vehicleNumberController.text = profile.vehNo;
        licenseNumberController.text = profile.licenseNo;
        aadhaarNumberController.text = profile.adhaarNo;
        fcdateController.text = formatDate(profile.fcDate);
        insdateController.text = formatDate(profile.insDate);
        genderValue.value = "M"; // Default since API has no gender

        // ✅ Safe assignment
        ref.read(selectedVehicleTypeProvider.notifier).state =
        (profile.vehTypeId.isNotEmpty && profile.vehTypeId != "0")
            ? int.tryParse(profile.vehTypeId)
            : null;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        ref.read(selectedVehicleSubTypeProvider.notifier).state =
        (profile.vehSubTypeId.isNotEmpty && profile.vehSubTypeId != "0")
            ? int.tryParse(profile.vehSubTypeId)
            : null;
      });


      Future.delayed(const Duration(milliseconds: 300), () {
        ref.read(selectedVehicleSubTypeProvider.notifier).state =
        profile.vehSubTypeId.isNotEmpty ? int.tryParse(profile.vehSubTypeId) : null;
      });

    } catch (e) {
      debugPrint("Failed to fetch profile: $e");
    }
  }

  void _updateButtonState() {
    setState(() {
      _isSaveEnabled = _areAllRequiredFieldsValid();
    });
  }

  /// Validate both personal info and vehicle info
  bool _areAllRequiredFieldsValid() {
    final isPersonalValid = nameController.text.isNotEmpty &&
        dobController.text.isNotEmpty &&
        address1Controller.text.isNotEmpty &&
        cityController.text.isNotEmpty;

    final isVehicleValid =
        vehicleNumberController.text.isNotEmpty &&
        licenseNumberController.text.isNotEmpty;

    return isPersonalValid && isVehicleValid;
  }


  // bool _isCurrentTabValid() {
  //   switch (_currentIndex) {
  //     case 0: // Personal Tab
  //       return nameController.text.isNotEmpty &&
  //           dobController.text.isNotEmpty &&
  //           address1Controller.text.isNotEmpty &&
  //           cityController.text.isNotEmpty;
  //     case 1: // Vehicle Tab
  //       return vehicleModelController.text.isNotEmpty &&
  //           vehicleNumberController.text.isNotEmpty &&
  //           licenseNumberController.text.isNotEmpty;
  //     case 2: // Documents Tab
  //       return true; // or add validation if needed
  //     default:
  //       return false;
  //   }
  // }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to pick image")));
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

  // Future<void> _selectDate() async {
  //   DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime(2000, 1, 1),
  //     firstDate: DateTime(1900),
  //     lastDate: DateTime.now(),
  //   );
  //   if (picked != null) {
  //     dobController.text = DateFormat("dd-MM-yyyy").format(picked);
  //     _updateButtonState();
  //   }
  // }
  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat("dd-MM-yyyy").format(picked);
      _updateButtonState();
    }
  }

  Future<void> _saveProfile() async {
    if (!_areAllRequiredFieldsValid()) return;

    final mobile = ref.read(mobileProvider);
    final selectedVehTypeId = ref.read(selectedVehicleTypeProvider);
    final selectedVehicleSubTypeId = ref.read(selectedVehicleSubTypeProvider);

    final riderId = SharedPrefsHelper.getRiderId();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print("---->>>>>Driver FCM Token: $fcmToken");

    // Fetch vehicle type/sub-type names
    final vehicleTypes = ref.read(vehicleTypesProvider).value ?? [];
    final vehicleSubTypes = selectedVehTypeId == null
        ? []
        : ref.read(vehicleSubTypesProvider(selectedVehTypeId)).value ?? [];

    final selectedVehTypeName = vehicleTypes.firstWhere(
          (type) => type.vehTypeid == selectedVehTypeId?.toString(),
      orElse: () => VehicleTypeModel(vehTypeid: "", vehTypeName: ""),
    ).vehTypeName;

    final selectedVehSubTypeName = vehicleSubTypes.firstWhere(
          (sub) => int.parse(sub.vehSubTypeId) == selectedVehicleSubTypeId,
      orElse: () => VehicleSubType(vehSubTypeId: "0", vehSubTypeName: ""),
    ).vehSubTypeName;

    final profile = DriverProfile(
      riderId: riderId,
      riderName: nameController.text,
      userName: nameController.text,
      password: "12345",
      mobileNo: mobNoController.text,
      gender: genderValue.value,
      dateOfBirth: dobController.text.isNotEmpty
          ? DateFormat("dd-MM-yyyy").parse(dobController.text).toIso8601String().split('T')[0]
          : "",
      add1: address1Controller.text,
      add2: address2Controller.text,
      add3: address3Controller.text,
      city: cityController.text,
      vehTypeId: selectedVehTypeId?.toString() ?? "",
      Vehtypename: selectedVehTypeName,       // ✅ Send type name
      vehSubTypeId: selectedVehicleSubTypeId?.toString() ?? "",
      VehsubTypename: selectedVehSubTypeName, // ✅ Send sub-type name
      vehNo: vehicleNumberController.text,
      fcDate: fcdateController.text.isNotEmpty
          ? DateFormat("dd-MM-yyyy").parse(fcdateController.text).toIso8601String().split('T')[0]
          : "",
      insDate: insdateController.text.isNotEmpty
          ? DateFormat("dd-MM-yyyy").parse(insdateController.text).toIso8601String().split('T')[0]
          : "",
      tokenKey: fcmToken ?? "",
      licenseNo: licenseNumberController.text,
      adhaarNo: aadhaarNumberController.text,
    );

    try {
      ApiResponse message;
      if (riderId == null || riderId.isEmpty) {
        /// 👉 New user → INSERT
        message = await ProfileRepository().insertUserProfile(profile);
      } else {
        /// 👉 Existing user → UPDATE
        message = await ProfileRepository().updateUserProfile(profile);
      }

      if (message.status == "success") {
        await SharedPrefsHelper.setDriverName(nameController.text);
        await SharedPrefsHelper.setDriverMobile(mobile);
        await SharedPrefsHelper.setDriverCity(cityController.text);
        await SharedPrefsHelper.setIsDriverProfileCompleted(true);


        if (selectedVehTypeId != null) {
          await SharedPrefsHelper.setDriverVehicleTypeId(selectedVehTypeId.toString());
        }
        if (selectedVehicleSubTypeId != null) {
          await SharedPrefsHelper.setDriverVehicleSubTypeId(selectedVehicleSubTypeId.toString());
        }

        if (fcmToken != null) {
          await SharedPrefsHelper.setDriverFcmToken(fcmToken);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );

        context.go(AppRoutes.driverHome);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${message.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final vehicleTypesAsync = ref.watch(vehicleTypesProvider);
    final selectedVehTypeId = ref.watch(selectedVehicleTypeProvider);
    final vehicleSubTypesAsync = selectedVehTypeId == null
        ? const AsyncValue<List<VehicleSubType>>.data([])
        : ref.watch(vehicleSubTypesProvider(selectedVehTypeId));

    // vehicleTypesAsync.when(
    //   data: (types) => print("Fetched ${types.length} vehicle types"),
    //   loading: () => print("Loading vehicle types..."),
    //   error: (e, st) => print("Error fetching vehicle types: $e"),
    // );

    // vehicleSubTypesAsync.when(
    //   data: (subTypes) => print("Fetched ${subTypes.length} vehicle sub-types"),
    //   loading: () => print("Loading vehicle sub-types..."),
    //   error: (e, st) => print("Error fetching vehicle sub-types: $e"),
    // );

    final tabs = [
      _personalTab(),
      _vehicleTab(vehicleTypesAsync, vehicleSubTypesAsync),
   //   _documentsTab(),
    ];

    return Scaffold(
        backgroundColor: AppColors.background,
        drawer: widget.isNewUser ? null : CommonDrawer(),
      appBar: AppBar(
        title: const Text(
          "Driver Profile",
          style: TextStyle(color: AppColors.buttonText, fontWeight: FontWeight.bold),
        ),
        backgroundColor:  AppColors.amber,
        foregroundColor: AppColors.buttonText,
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
                      ?  AppColors.primary
                      : AppColors.secondary,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: _isSaveEnabled
                    ?  AppColors.success
                    : AppColors.icon,
                borderRadius: BorderRadius.circular(24),
                boxShadow: _isSaveEnabled
                    ? [
                        const BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.save,  color: AppColors.buttonText,),
                  SizedBox(width: 8),
                  Text(
                    "Save Profile",
                    style: TextStyle(
                      color: AppColors.buttonText,
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
        backgroundColor: AppColors.buttonText,
        currentIndex: _currentIndex,
        selectedItemColor:  AppColors.primary,
        unselectedItemColor: AppColors.icon,
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
            icon: Icon(Icons.directions_car),
            label: "Vehicle",
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.upload_file),
          //   label: "Documents",
          // ),
        ],
      ),
    );
  }

  Widget _tabCard({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.buttonText,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
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
          prefixIconColor: AppColors.icon,
          fillColor: AppColors.buttonText,
          focusedBorderColor: AppColors.text,
          enabledBorderColor: AppColors.secondary,
        ),
        const SizedBox(height: 16),
        CommonTextField(
          label: "Mobile No",
          controller: mobNoController,
          prefixIcon: Icons.phone_android,
          prefixIconColor: AppColors.icon,
          fillColor: AppColors.buttonText,
          focusedBorderColor: AppColors.text,
          enabledBorderColor: AppColors.text,
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
                fillColor: AppColors.buttonText,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.text!, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.text,
                    width: 2,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _selectDate(dobController),
          child: AbsorbPointer(
            child: CommonTextField(
              label: "Date of Birth",
              controller: dobController,
              prefixIcon: Icons.calendar_today,
              prefixIconColor: AppColors.icon,
              fillColor: AppColors.buttonText,
              focusedBorderColor: AppColors.text,
              enabledBorderColor: AppColors.text,
            ),
          ),
        ),
        const SizedBox(height: 16),
        CommonTextField(
          label: "Address Line 1",
          controller: address1Controller,
          prefixIcon: Icons.home,
          prefixIconColor: AppColors.icon,
          fillColor: AppColors.buttonText,
          focusedBorderColor: AppColors.text,
          enabledBorderColor: AppColors.text,
        ),
        const SizedBox(height: 12),
        CommonTextField(
          label: "Address Line 2",
          controller: address2Controller,
          prefixIcon: Icons.home,
          prefixIconColor: AppColors.icon,
          fillColor: AppColors.buttonText,
          focusedBorderColor: AppColors.text,
          enabledBorderColor: AppColors.text,
        ),
        const SizedBox(height: 12),
        CommonTextField(
          label: "Address Line 3",
          controller: address3Controller,
          prefixIcon: Icons.home,
          prefixIconColor: AppColors.icon,
          fillColor: AppColors.buttonText,
          focusedBorderColor: AppColors.text,
          enabledBorderColor: AppColors.text,
        ),
        const SizedBox(height: 12),
        CommonTextField(
          label: "City",
          controller: cityController,
          prefixIcon: Icons.location_city,
          prefixIconColor: AppColors.icon,
          fillColor: AppColors.buttonText,
          focusedBorderColor: AppColors.text,
          enabledBorderColor: AppColors.text,
        ),
      ],
    ),
  );

  Widget _vehicleTab(
      AsyncValue<List<VehicleTypeModel>> vehicleTypesAsync,
      AsyncValue<List<VehicleSubType>> vehicleSubTypesAsync,
      ) => _tabCard(
    child: Column(
      children: [
        // Vehicle Type Dropdown
        vehicleTypesAsync.when(
          data: (vehicleTypes) {
            final selectedType = ref.watch(selectedVehicleTypeProvider);
            final validValue = vehicleTypes.any((t) => t.vehTypeid == selectedType?.toString())
                ? selectedType?.toString()
                : null;

            return DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Vehicle Type",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.buttonText,
              ),
              value: validValue,
              items: vehicleTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type.vehTypeid,
                  child: Text(type.vehTypeName),
                );
              }).toList(),
              onChanged: (value) {
                final int? newVehTypeId = value != null ? int.tryParse(value) : null;
                ref.read(selectedVehicleTypeProvider.notifier).state = newVehTypeId;
                ref.read(selectedVehicleSubTypeProvider.notifier).state = null;
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text("Error: $e"),
        ),

        const SizedBox(height: 16),

        // Vehicle Sub-Type Dropdown
        vehicleSubTypesAsync.when(
          data: (subTypes) {
            final selectedSubType = ref.watch(selectedVehicleSubTypeProvider);
            final validValue = subTypes.any((s) => int.parse(s.vehSubTypeId) == selectedSubType)
                ? selectedSubType
                : null;

            if (subTypes.isEmpty) return const SizedBox();

            return DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: "Vehicle Sub-Type",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.buttonText,
              ),
              value: validValue,
              items: subTypes.map((sub) {
                return DropdownMenuItem<int>(
                  value: int.parse(sub.vehSubTypeId),
                  child: Text(sub.vehSubTypeName),
                );
              }).toList(),
              onChanged: (value) {
                ref.read(selectedVehicleSubTypeProvider.notifier).state = value;
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text("Error: $e"),
        ),

        const SizedBox(height: 16),

        CommonTextField(
          label: "Vehicle Number",
          controller: vehicleNumberController,
          prefixIcon: Icons.confirmation_number,
          prefixIconColor: AppColors.icon,
          fillColor: AppColors.buttonText,
          focusedBorderColor: AppColors.text,
          enabledBorderColor: AppColors.text,
        ),

        const SizedBox(height: 16),

        GestureDetector(
          onTap: () => _selectDate(fcdateController),
          child: AbsorbPointer(
            child: CommonTextField(
              label: "FC Date",
              controller: fcdateController,
              prefixIcon: Icons.date_range,
              prefixIconColor: AppColors.icon,
              fillColor: AppColors.buttonText,
              focusedBorderColor: AppColors.text,
              enabledBorderColor: AppColors.text,
              keyboardType: TextInputType.datetime,
            ),
          ),
        ),

        const SizedBox(height: 16),

        GestureDetector(
          onTap: () => _selectDate(insdateController),
          child: AbsorbPointer(
            child: CommonTextField(
              label: "Insurance Date",
              controller: insdateController,
              prefixIcon: Icons.date_range,
              prefixIconColor: AppColors.icon,
              fillColor: AppColors.buttonText,
              focusedBorderColor: AppColors.text,
              enabledBorderColor: AppColors.text,
              keyboardType: TextInputType.datetime,
            ),
          ),
        ),

        const SizedBox(height: 16),

        CommonTextField(
          label: "License Number",
          controller: licenseNumberController,
          prefixIcon: Icons.badge,
          prefixIconColor: AppColors.icon,
          fillColor: AppColors.buttonText,
          focusedBorderColor: AppColors.text,
          enabledBorderColor: AppColors.text,
        ),

        const SizedBox(height: 16),

        CommonTextField(
          label: "Aadhaar Number",
          controller: aadhaarNumberController,
          prefixIcon: Icons.badge,
          prefixIconColor: AppColors.icon,
          fillColor: AppColors.buttonText,
          focusedBorderColor: AppColors.text,
          enabledBorderColor: AppColors.text,
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

        _uploadTile(
          "aadhar",
          "Aadhar / ID Proof (Optional)",
          Icons.perm_identity,
        ),
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
          border: Border.all(color: AppColors.secondary!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyText.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            file == null
                ? const Icon(Icons.upload_file, color: AppColors.primary)
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
}
