import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanHardwareScreen extends StatefulWidget {
  const ScanHardwareScreen({super.key});

  @override
  State<ScanHardwareScreen> createState() => _ScanHardwareScreenState();
}

class _ScanHardwareScreenState extends State<ScanHardwareScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Hardware'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _scannerController.stop();
                  Navigator.pop(context, barcode.rawValue);
                }
              }
            },
          ),
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        // Scanner border
        Center(
          child: Container(
            width: 320,
            height: 240, 
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF5eb052), width: 3.0),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // "Place barcode inside the box" text
        Positioned(
          bottom: 150,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Place barcode inside the box',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
