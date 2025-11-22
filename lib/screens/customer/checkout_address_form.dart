import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/address_model.dart';
import '../../theme/app_theme.dart';

/// Address Form Screen
/// 
/// Used for creating and editing delivery addresses
class CheckoutAddressForm extends StatefulWidget {
  final AddressModel? address;
  final bool isEditing;

  const CheckoutAddressForm({
    super.key,
    this.address,
    required this.isEditing,
  });

  @override
  State<CheckoutAddressForm> createState() => _CheckoutAddressFormState();
}

class _CheckoutAddressFormState extends State<CheckoutAddressForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  final _titleController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');
  
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.address != null) {
      final addr = widget.address!;
      _titleController.text = addr.title;
      _addressLine1Controller.text = addr.addressLine1;
      _addressLine2Controller.text = addr.addressLine2 ?? '';
      _cityController.text = addr.city;
      _stateController.text = addr.state;
      _postalCodeController.text = addr.postalCode;
      _countryController.text = addr.country;
      _isDefault = addr.isDefault;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final addressData = {
        'title': _titleController.text.trim(),
        'address_line_1': _addressLine1Controller.text.trim(),
        'address_line_2': _addressLine2Controller.text.trim().isEmpty 
            ? null 
            : _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'is_default': _isDefault,
      };

      AddressModel savedAddress;
      
      if (widget.isEditing && widget.address != null) {
        final response = await _apiService.updateAddress(
          addressId: widget.address!.id,
          addressData: addressData,
        );
        savedAddress = AddressModel.fromJson(response);
      } else {
        final response = await _apiService.createAddress(addressData);
        savedAddress = AddressModel.fromJson(response);
      }

      if (mounted) {
        Navigator.of(context).pop(savedAddress);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving address: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Address' : 'Add New Address'),
        backgroundColor: AppTheme.bgWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 40 : isTablet ? 24 : 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Address Title *',
                  hintText: 'e.g., Home, Work',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an address title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address Line 1
              TextFormField(
                controller: _addressLine1Controller,
                decoration: InputDecoration(
                  labelText: 'Address Line 1 *',
                  hintText: 'Street address, house number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter address line 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address Line 2
              TextFormField(
                controller: _addressLine2Controller,
                decoration: InputDecoration(
                  labelText: 'Address Line 2',
                  hintText: 'Apartment, suite, etc. (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // City & State Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Postal Code & Country Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _postalCodeController,
                      decoration: InputDecoration(
                        labelText: 'Postal Code *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (value.trim().length < 5) {
                          return 'Invalid postal code';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        labelText: 'Country *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Default Address Checkbox
              CheckboxListTile(
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
                title: const Text('Set as default address'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isDesktop ? 18 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.isEditing ? 'Update Address' : 'Save Address',
                          style: TextStyle(
                            fontSize: isDesktop ? 18 : 16,
                            fontWeight: FontWeight.bold,
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

