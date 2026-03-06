import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'scan_hardware_screen.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _selectedLocationId;
  
  String? _scannedBarcode;
  Map<String, dynamic>? _hardwareData;
  bool _isLoading = false;
  
  // For now, mock user ID.
  final int _currentUserId = 1;

  Future<void> _navigateToScan() async {
    final scannedValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScanHardwareScreen()),
    );

    if (scannedValue != null) {
      setState(() {
        _isLoading = true;
        _scannedBarcode = scannedValue;
        _hardwareData = null; // reset previously scanned item
      });

      try {
        final result = await ApiService.scanHardware(scannedValue);
        setState(() {
          _hardwareData = result['hardware'];
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Scanned: ${_hardwareData?['hardware_name']}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
           );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _detectLocation() async {
    setState(() {
       _isLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      
      // Since mapping GPS to internal Stock ID needs custom logic offline/online, 
      // let's default populate a sample ID or prompt.
      setState(() {
         _selectedLocationId = 2; // Mock location Mumbai (ID 2)
      });
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Detected nearby location: Mumbai'), backgroundColor: Colors.green),
         );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
         );
      }
    } finally {
      setState(() {
         _isLoading = false;
      });
    }
  }

  Future<void> _markLocation() async {
     if (_hardwareData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please scan hardware first'), backgroundColor: Colors.orange),
        );
        return;
     }

     if (_selectedLocationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a location'), backgroundColor: Colors.orange),
        );
        return;
     }

     setState(() {
        _isLoading = true;
     });

     try {
        await ApiService.markLocation(_hardwareData!['hardware_id'], _selectedLocationId!, _currentUserId);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Location marked successfully!'), backgroundColor: Colors.green),
           );
           // Clear after success
           setState(() {
              _scannedBarcode = null;
              _hardwareData = null;
              _selectedLocationId = null;
           });
        }
     } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update: ${e.toString()}'), backgroundColor: Colors.red),
           );
        }
     } finally {
        setState(() {
           _isLoading = false;
        });
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Dashboard', 
          style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF5eb052)))
        : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepTitle('Step 1 – Scan Hardware'),
              const SizedBox(height: 12),
              _buildOutlineButton(
                icon: Icons.qr_code_scanner, 
                label: _hardwareData != null ? 'Scanned: ${_hardwareData!['hardware_name']}' : 'Scan Hardware', 
                onTap: _navigateToScan,
              ),
              const SizedBox(height: 32),
              
              _buildStepTitle('Step 2 – Detect Current Location'),
              const SizedBox(height: 12),
              _buildOutlineButton(
                icon: Icons.location_on, 
                label: 'Detect Location', 
                onTap: _detectLocation,
              ),
              const SizedBox(height: 32),
              
              _buildStepTitle('Select Location'),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedLocationId,
                hint: Text('Choose a location', style: TextStyle(color: Colors.grey.shade600)),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Pune')),
                  DropdownMenuItem(value: 2, child: Text('Mumbai')),
                  DropdownMenuItem(value: 3, child: Text('Bangalore')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLocationId = value;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
              ),
              const Spacer(),
              
              ElevatedButton(
                onPressed: _markLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5eb052), // Green from UI
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Mark Location'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildOutlineButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F4FB),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF6B5B95)), // Purple tint
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B5B95),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
