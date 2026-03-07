import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Define warehouse coordinates 
  final Map<int, Map<String, dynamic>> _warehouseLocations = {
    1: {'name': 'Pune', 'lat': 18.5204, 'lng': 73.8567},
    2: {'name': 'Mumbai', 'lat': 19.0760, 'lng': 72.8777},
    3: {'name': 'Bangalore', 'lat': 12.9716, 'lng': 77.5946},
  };
  
  // Acceptable radius in meters (e.g., 100km for demo purposes, adjust as needed)
  final double _allowedRadiusMeters = 100000;

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

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10)); // Add timeout to prevent infinite web loading
      } catch (locationError) {
        throw Exception("Could not get GPS lock. Please ensure location services are enabled.");
      }
      
      if (position == null) {
          throw Exception("Received null position from GPS.");
      }

      int? nearestLocationId;
      double shortestDistance = double.infinity;
      String nearestLocationName = "";

      // Calculate distance to each warehouse
      _warehouseLocations.forEach((id, loc) {
        double distanceInMeters = Geolocator.distanceBetween(
          position!.latitude, 
          position.longitude, 
          loc['lat'] as double, 
          loc['lng'] as double
        );

        if (distanceInMeters < shortestDistance) {
          shortestDistance = distanceInMeters;
          if (distanceInMeters <= _allowedRadiusMeters) {
             nearestLocationId = id;
             nearestLocationName = loc['name'] as String;
          }
        }
      });
      
      if (mounted) {
        if (nearestLocationId != null) {
          setState(() {
             _selectedLocationId = nearestLocationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Detected nearby location: $nearestLocationName'), backgroundColor: Colors.green),
          );
        } else {
          // Nearest location is outside the allowed radius
          setState(() {
             _selectedLocationId = null; 
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No inventory warehouse found near your current location.'), backgroundColor: Colors.red),
          );
        }
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Inventory Workspace', 
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF5eb052)))
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Workflow Header
                    Text(
                      "Location Assignment",
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Scan a piece of hardware and link it to its physical warehouse location using GPS.",
                      style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 40),

                    // Card 1: Scanning
                    _buildStepCard(
                      stepNumber: 1,
                      title: 'Identify Hardware',
                      description: 'Scan the barcode on the hardware item.',
                      icon: Icons.qr_code_scanner_rounded,
                      isDone: _hardwareData != null,
                      content: [
                        if (_hardwareData != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(child: Text("Scanned: ${_hardwareData!['hardware_name']}", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.green.shade700))),
                              ]
                            )
                          ),
                        ],
                        ElevatedButton.icon(
                          onPressed: _navigateToScan,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(_hardwareData != null ? 'Scan Different Item' : 'Open Camera Scanner'),
                          style: _actionButtonStyle(isPrimary: _hardwareData == null),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Card 2: GPS
                    _buildStepCard(
                      stepNumber: 2,
                      title: 'Verify Location',
                      description: 'Detect your physical coordinates to unlock the nearest warehouse.',
                      icon: Icons.my_location_rounded,
                      isDone: _selectedLocationId != null,
                      content: [
                        ElevatedButton.icon(
                          onPressed: _detectLocation,
                          icon: const Icon(Icons.gps_fixed),
                          label: const Text('Detect GPS Coordinates'),
                          style: _actionButtonStyle(isPrimary: _hardwareData != null && _selectedLocationId == null),
                        ),
                        const SizedBox(height: 24),
                        // Locked Dropdown
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Detected Warehouse',
                            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                            filled: true,
                            fillColor: _selectedLocationId != null ? Colors.white : Colors.grey.shade100,
                            prefixIcon: Icon(_selectedLocationId != null ? Icons.domain_verification : Icons.lock_outline, 
                                             color: _selectedLocationId != null ? Colors.green : Colors.grey.shade500),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                          child: Text(
                            _selectedLocationId != null 
                              ? _warehouseLocations[_selectedLocationId]!['name'] as String 
                              : 'Waiting for GPS lock...',
                            style: GoogleFonts.inter(
                              fontSize: 16, 
                              fontWeight: _selectedLocationId != null ? FontWeight.bold : FontWeight.normal,
                              color: _selectedLocationId != null ? Colors.black87 : Colors.grey.shade500
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Card 3: Submit Location Assignment
                    _buildStepCard(
                      stepNumber: 3,
                      title: 'Finalize Assignment',
                      description: 'Link the scanned hardware item securely to the verified GPS location.',
                      icon: Icons.cloud_upload_rounded,
                      isDone: false, // You could toggle this to true right before clearing, but since it clears instantly, false is fine
                      content: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_hardwareData != null && _selectedLocationId != null) ? _markLocation : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5eb052),
                              disabledBackgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text('Complete Assignment', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildStepCard({required int stepNumber, required String title, required String description, required IconData icon, required bool isDone, required List<Widget> content}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: isDone ? Colors.green.shade300 : Colors.transparent, width: 2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: isDone ? Colors.green.shade50 : const Color(0xFFF6F4FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Icon(isDone ? Icons.check : icon, color: isDone ? Colors.green : const Color(0xFF6B5B95), size: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Step $stepNumber: $title", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text(description, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
                  ],
                )
              )
            ],
          ),
          const SizedBox(height: 24),
          ...content,
        ],
      )
    );
  }

  ButtonStyle _actionButtonStyle({required bool isPrimary}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isPrimary ? const Color(0xFF6B5B95) : Colors.grey.shade100,
      foregroundColor: isPrimary ? Colors.white : Colors.black87,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}
