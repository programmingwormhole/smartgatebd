import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/admin_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/admin_service.dart';

class CreateResidentScreen extends StatefulWidget {
  const CreateResidentScreen({super.key});

  @override
  State<CreateResidentScreen> createState() => _CreateResidentScreenState();
}

class _CreateResidentScreenState extends State<CreateResidentScreen> {
  final AdminController _adminController = Get.find<AdminController>();
  final AuthController _authController = Get.find<AuthController>();
  final AdminService _adminService = AdminService();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _maintenanceFeeController;
  late TextEditingController _rentController;
  late TextEditingController _billGenerateDayController;

  String _selectedRole = 'resident';
  bool _isSubmitting = false;
  bool _isLoadingStructure = false;
  bool _isSuperadmin = false;

  int? _selectedBuildingId;
  int? _selectedBlockId;
  int? _selectedFloorId;
  int? _selectedFlatId;

  List<Map<String, dynamic>> _buildings = [];
  List<Map<String, dynamic>> _blocks = [];
  List<Map<String, dynamic>> _floors = [];
  List<Map<String, dynamic>> _flats = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _maintenanceFeeController = TextEditingController();
    _rentController = TextEditingController();
    _billGenerateDayController = TextEditingController(text: '1');
    
    // Check if user is superadmin
    _isSuperadmin = _authController.user != null && 
                    _authController.user!.role.toLowerCase() == 'superadmin';
    
    // If not superadmin, set the building ID from auth
    if (!_isSuperadmin) {
      _selectedBuildingId = _authController.user?.buildingId;
    }
    
    _loadBuildingStructureData();
  }

  Future<void> _loadBuildingStructureData() async {
    setState(() => _isLoadingStructure = true);
    try {
      // If superadmin, load all buildings
      if (_isSuperadmin) {
        final buildings = await _adminService.getAllBuildings();
        setState(() {
          _buildings = List<Map<String, dynamic>>.from(buildings);
          // Set first building as default if available
          if (_buildings.isNotEmpty && _selectedBuildingId == null) {
            _selectedBuildingId = _buildings[0]['id'];
            _adminController.setActiveBuildingId(_selectedBuildingId);
          }
        });
      }

      // Load building structure for selected building
      if (_selectedBuildingId != null) {
        _adminController.setActiveBuildingId(_selectedBuildingId);
        await _adminController.fetchBuildingStructure(buildingId: _selectedBuildingId);
        
        if (_adminController.buildingStructure.isNotEmpty) {
          setState(() {
            _blocks = List<Map<String, dynamic>>.from(
              _adminController.buildingStructure['blocks'] ?? [],
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading building structure: $e');
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load ${_isSuperadmin ? 'buildings' : 'building structure'}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStructure = false);
      }
    }
  }

  void _onBuildingChanged(int? buildingId) {
    setState(() {
      _selectedBuildingId = buildingId;
      _selectedBlockId = null;
      _selectedFloorId = null;
      _selectedFlatId = null;
      _blocks = [];
      _floors = [];
      _flats = [];
    });

    // Reload building structure for the selected building
    if (buildingId != null) {
      _adminController.setActiveBuildingId(buildingId);
      setState(() => _isLoadingStructure = true);
      _adminController.fetchBuildingStructure(buildingId: buildingId).then((_) {
        if (mounted && _adminController.buildingStructure.isNotEmpty) {
          setState(() {
            _blocks = List<Map<String, dynamic>>.from(
              _adminController.buildingStructure['blocks'] ?? [],
            );
            _isLoadingStructure = false;
          });
        }
      }).catchError((e) {
        if (mounted) {
          setState(() => _isLoadingStructure = false);
          Get.snackbar(
            'Error',
            'Failed to load building structure',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      });
    }
  }

  void _onBlockChanged(int? blockId) {
    setState(() {
      _selectedBlockId = blockId;
      _selectedFloorId = null;
      _selectedFlatId = null;
      _floors = [];
      _flats = [];

      if (blockId != null) {
        final selectedBlock =
            _blocks.firstWhere((b) => b['id'] == blockId, orElse: () => {});
        if (selectedBlock.isNotEmpty) {
          _floors = List<Map<String, dynamic>>.from(
            selectedBlock['floors'] ?? [],
          );
        }
      }
    });
  }

  void _onFloorChanged(int? floorId) {
    setState(() {
      _selectedFloorId = floorId;
      _selectedFlatId = null;
      _flats = [];

      if (floorId != null) {
        final selectedFloor =
            _floors.firstWhere((f) => f['id'] == floorId, orElse: () => {});
        if (selectedFloor.isNotEmpty) {
          _flats = List<Map<String, dynamic>>.from(
            selectedFloor['flats'] ?? [],
          );
        }
      }
    });
  }

  void _onFlatChanged(int? flatId) {
    setState(() {
      _selectedFlatId = flatId;
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Validation Error',
        'Please fill in all required fields',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (_isSuperadmin && _selectedBuildingId == null) {
      Get.snackbar(
        'Validation Error',
        'Please select a building',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedBlockId == null) {
      Get.snackbar(
        'Validation Error',
        'Please select a block',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedFloorId == null) {
      Get.snackbar(
        'Validation Error',
        'Please select a floor',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedFlatId == null) {
      Get.snackbar(
        'Validation Error',
        'Please select a flat',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final buildingId = _selectedBuildingId ?? _authController.user?.buildingId ?? 1;

      final residentData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.isNotEmpty
            ? _emailController.text.trim()
            : null,
        'role': _selectedRole,
        'flat_id': _selectedFlatId,
        'block_id': _selectedBlockId,
        'floor_id': _selectedFloorId,
        'monthly_maintenance_fee': _parseAmount(_maintenanceFeeController.text),
        'rent': _parseAmount(_rentController.text),
        'bill_generate_day': _parseBillingDay(_billGenerateDayController.text),
      };

      final success = await _adminController.addResident(
        buildingId,
        residentData,
      );

      if (mounted) {
        if (success) {
          Get.back();
          Get.snackbar(
            'Success',
            'Resident created successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          debugPrint('Failed to create resident');
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error submitting form: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _maintenanceFeeController.dispose();
    _rentController.dispose();
    _billGenerateDayController.dispose();
    super.dispose();
  }

  double? _parseAmount(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  int? _parseBillingDay(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  Widget _buildLocationSelectionShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              width: 150,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Container(
              height: 56,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Container(
              height: 56,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Container(
              height: 56,
              color: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create New Resident'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryNavy),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Location Selection Section
              if (_isLoadingStructure)
                _buildLocationSelectionShimmer()
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Flat Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Building Selection (for superadmin)
                      if (_isSuperadmin) ...[
                        DropdownButtonFormField<int>(
                          value: _selectedBuildingId,
                          decoration: InputDecoration(
                            labelText: 'Building*',
                            prefixIcon: const Icon(Icons.apartment),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: _buildings.map((building) {
                            return DropdownMenuItem<int>(
                              value: building['id'],
                              child: Text(building['name'] ?? 'Unknown Building'),
                            );
                          }).toList(),
                          onChanged: _onBuildingChanged,
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a building';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Block Selection
                      DropdownButtonFormField<int>(
                        value: _selectedBlockId,
                        decoration: InputDecoration(
                          labelText: 'Block*',
                          prefixIcon: const Icon(Icons.business),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _blocks.map((block) {
                          return DropdownMenuItem<int>(
                            value: block['id'],
                            child: Text(block['name'] ?? 'Unknown Block'),
                          );
                        }).toList(),
                        onChanged: _onBlockChanged,
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a block';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Floor Selection
                      DropdownButtonFormField<int>(
                        value: _selectedFloorId,
                        decoration: InputDecoration(
                          labelText: 'Floor*',
                          prefixIcon: const Icon(Icons.layers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _floors.map((floor) {
                          return DropdownMenuItem<int>(
                            value: floor['id'],
                            child: Text('Floor ${floor['floor_number'] ?? ''}'),
                          );
                        }).toList(),
                        onChanged: _selectedBlockId != null
                            ? _onFloorChanged
                            : null,
                        validator: (value) {
                          if (_selectedBlockId != null && value == null) {
                            return 'Please select a floor';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Flat Selection
                      DropdownButtonFormField<int>(
                        value: _selectedFlatId,
                        decoration: InputDecoration(
                          labelText: 'Flat*',
                          prefixIcon: const Icon(Icons.house_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _flats.map((flat) {
                          return DropdownMenuItem<int>(
                            value: flat['id'],
                            child: Text('Flat ${flat['flat_number'] ?? ''}'),
                          );
                        }).toList(),
                        onChanged: _selectedFloorId != null
                            ? _onFlatChanged
                            : null,
                        validator: (value) {
                          if (_selectedFloorId != null && value == null) {
                            return 'Please select a flat';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Resident Details Section
              const Text(
                'Resident Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name*',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Full name is required';
                  }
                  if (value.length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number*',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.length < 10) {
                    return 'Phone number must be at least 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final emailRegex =
                        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Billing Defaults',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maintenanceFeeController,
                decoration: InputDecoration(
                  labelText: 'Monthly Maintenance Fee (Optional)',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount < 0) {
                    return 'Enter a valid non-negative amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rentController,
                decoration: InputDecoration(
                  labelText: 'Monthly Rent (Optional)',
                  prefixIcon: const Icon(Icons.home_work_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount < 0) {
                    return 'Enter a valid non-negative amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _billGenerateDayController,
                decoration: InputDecoration(
                  labelText: 'Billing Date (Day 1-28)',
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final day = int.tryParse(value.trim());
                  if (day == null || day < 1 || day > 28) {
                    return 'Billing day must be between 1 and 28';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Role Selection Section
              const Text(
                'Resident Role',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Resident'),
                      subtitle: const Text('Regular resident'),
                      value: 'resident',
                      groupValue: _selectedRole,
                      activeColor: AppColors.primaryNavy,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    RadioListTile<String>(
                      title: const Text('Committee Member'),
                      subtitle: const Text('Part of building committee'),
                      value: 'committee',
                      groupValue: _selectedRole,
                      activeColor: AppColors.primaryNavy,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    RadioListTile<String>(
                      title: const Text('Admin'),
                      subtitle: const Text('Building administrator'),
                      value: 'admin',
                      groupValue: _selectedRole,
                      activeColor: AppColors.primaryNavy,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Resident',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => Get.back(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
