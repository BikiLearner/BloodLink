import 'dart:convert';
import 'package:blood_link_flutter/provider/add_blood_order_provider.dart';
import 'package:blood_link_flutter/provider/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'extra_functions.dart';
import 'google_map_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditProfileScreen({super.key, required this.profileData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  String? _selectedBloodGroup;
  bool isLoading = false;
  String? errorMessage;

  final List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  List<TextEditingController> _medicalRecordControllers = [];

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.profileData['address'] ?? '');
    _selectedBloodGroup = widget.profileData['bloodGroup'];

    final List<dynamic> medicalRecords = widget.profileData['medicalRecords'] ?? [];
    if (medicalRecords.isEmpty) {
      _medicalRecordControllers.add(TextEditingController());
    } else {
      _medicalRecordControllers = medicalRecords
          .map((record) => TextEditingController(text: record.toString()))
          .toList();
    }
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final medicalRecords = _medicalRecordControllers
          .map((controller) => controller.text.trim())
          .where((record) => record.isNotEmpty)
          .toList();

      final body = {
        "bloodGroup": _selectedBloodGroup,
        "address": _addressController.text.trim(),
      };

      final response = await http.put(
        Uri.parse('https://bloodlink-flsd.onrender.com/api/patients/complete-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      print('response code profile ${response.statusCode}');
      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        setState(() => errorMessage = 'Failed to update profile');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _addMedicalRecord() {
    setState(() {
      _medicalRecordControllers.add(TextEditingController());
    });
  }

  void _removeMedicalRecord(int index) {
    setState(() {
      _medicalRecordControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    for (var controller in _medicalRecordControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Soft grey for healthcare
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF212121),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.2),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFD32F2F), // Red accent
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: const Color(0xFFD32F2F),
              strokeWidth: 3,
            ),
            const SizedBox(height: 12),
            Text(
              'Updating Profile...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Error Message
              if (errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD32F2F)),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              // Blood Group Dropdown
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD32F2F).withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    items: bloodGroups
                        .map((group) => DropdownMenuItem(
                      value: group,
                      child: Text(
                        group,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedBloodGroup = value),
                    decoration: InputDecoration(
                      labelText: 'Blood Group',
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) =>
                    value == null ? 'Please select a blood group' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Address Field
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD32F2F).withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Selector<ProfileProvider, bool>(
                    selector: (_, provider) => provider.isCurrentLocationLoading,
                    builder: (context, isAddressLoading, child) {
                      final provider = context.read<ProfileProvider>();

                      return TextFormField(
                        controller: provider.addressController, // same controller logic
                        decoration: InputDecoration(
                          labelText: 'Address',
                          labelStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: isAddressLoading
                              ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
                              ),
                            ),
                          )
                              : Icon(
                            Icons.location_on,
                            color: Color(0xFFD32F2F),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.my_location,
                                  color: Color(0xFFD32F2F),
                                ),
                                onPressed: () => provider.fetchCurrentAddress(context),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.map,
                                  color: Color(0xFFD32F2F),
                                ),
                                onPressed: () async {

                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MapPickerPage(
                                        ),
                                      ),
                                    );
                                    if (result != null &&
                                        result is Map &&
                                        result['address'] != null) {
                                      provider.addressController.text = result['address'] as String;
                                    }
                                },
                              ),
                            ],
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF212121),
                        ),
                        validator: (value) =>
                        value!.isEmpty ? 'Please enter an address' : null,
                      );
                    },
                  ),

                ),
              ),
              const SizedBox(height: 20),
              // Update Button
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 700),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD32F2F).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Update Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}