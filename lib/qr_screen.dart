import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: unused_element
class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<QRViewExample> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  var _isFlashOff = true;

  bool _isInvalidURL = false;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "QR Suckaner",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            onPressed: () {
              _onFlipCamera(controller!);
            },
            icon: const Icon(
              Icons.flip_camera_android,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              _onToggleFlash(controller!);
            },
            icon: Icon(
              _isFlashOff ? Icons.flashlight_off : Icons.flashlight_on,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              overlay: QrScannerOverlayShape(
                borderColor: Colors.white,
              ),
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: _isInvalidURL
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'URL is Invalid!',
                          style: TextStyle(color: Colors.purple, fontSize: 20),
                        ),
                        IconButton(
                            onPressed: () {
                              controller!.resumeCamera();
                            },
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.purple,
                            ))
                      ],
                    )
                  : const Text(
                      'Fit QR Code in Frame',
                      style: TextStyle(color: Colors.purple, fontSize: 20),
                    ),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      controller.stopCamera();
      TextEditingController controller0 =
          TextEditingController(text: "${result!.code}");
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text("Scanned"),
          content: TextField(
            controller: controller0,
            readOnly: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.resumeCamera();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _launchUrl(result!.code, context);
              },
              child: const Text("Launch"),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _launchUrl(String? url, BuildContext context) async {
    try {
      if (!await launchUrl(Uri.parse(url!))) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      setState(() {
        Navigator.of(context).pop();
        _isInvalidURL = true;
      });
    }
  }

  void _onFlipCamera(QRViewController controller) {
    controller.flipCamera();
  }

  void _onToggleFlash(QRViewController controller) {
    controller.toggleFlash();
    setState(() {
      _isFlashOff = !_isFlashOff;
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
