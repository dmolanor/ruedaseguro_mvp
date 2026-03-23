import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';

enum DocumentScannerMode { document, vehiclePhoto }

class DocumentScanner extends StatefulWidget {
  const DocumentScanner({
    super.key,
    required this.instruction,
    required this.onCapture,
    this.mode = DocumentScannerMode.document,
    this.onCancel,
  });

  final String instruction;
  final Future<void> Function(File file) onCapture;
  final VoidCallback? onCancel;
  final DocumentScannerMode mode;

  @override
  State<DocumentScanner> createState() => _DocumentScannerState();
}

class _DocumentScannerState extends State<DocumentScanner>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _permissionDeniedForever = false;
  bool _isTorchOn = false;
  File? _capturedFile;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      await _initCamera();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _hasPermission = false;
        _permissionDeniedForever = true;
      });
    } else {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        setState(() => _hasPermission = true);
        await _initCamera();
      } else if (result.isPermanentlyDenied) {
        setState(() {
          _hasPermission = false;
          _permissionDeniedForever = true;
        });
      } else {
        setState(() => _hasPermission = false);
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;
      final backCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      _controller = CameraController(
        backCamera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } on Exception {
      // Camera init failed — show gallery fallback
    }
  }

  Future<void> _toggleTorch() async {
    if (_controller == null || !_isInitialized) return;
    try {
      _isTorchOn = !_isTorchOn;
      await _controller!.setFlashMode(
        _isTorchOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } on Exception {
      // Torch not supported on this device
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_isInitialized || _isProcessing) return;
    setState(() => _isProcessing = true);
    // Capture screen size before async gap to avoid BuildContext warning
    final screenSize = MediaQuery.of(context).size;
    try {
      final xFile = await _controller!.takePicture();
      final file = File(xFile.path);
      final cropped = await _cropToFrame(file, screenSize);
      setState(() {
        _capturedFile = cropped;
        _isProcessing = false;
      });
    } on Exception {
      setState(() => _isProcessing = false);
    }
  }

  /// Crops [original] to the overlay frame area so OCR only processes
  /// the document region, not background text visible outside the frame.
  Future<File> _cropToFrame(File original, Size screenSize) async {
    try {
      final bytes = await original.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      final imgW = image.width.toDouble();
      final imgH = image.height.toDouble();

      // Frame dimensions — must match _ScanOverlay exactly
      final isVehicle = widget.mode == DocumentScannerMode.vehiclePhoto;
      final frameScreenW = screenSize.width * (isVehicle ? 0.92 : 0.88);
      final frameScreenH =
          isVehicle ? frameScreenW * 0.6 : frameScreenW * 0.63;
      final frameLeft = (screenSize.width - frameScreenW) / 2;
      final frameTop = (screenSize.height - frameScreenH) / 2;

      // Map screen coordinates → image pixels (proportional)
      final cropL =
          (frameLeft / screenSize.width * imgW).clamp(0.0, imgW);
      final cropT =
          (frameTop / screenSize.height * imgH).clamp(0.0, imgH);
      final cropW =
          (frameScreenW / screenSize.width * imgW).clamp(1.0, imgW - cropL);
      final cropH =
          (frameScreenH / screenSize.height * imgH).clamp(1.0, imgH - cropT);

      final srcRect = Rect.fromLTWH(cropL, cropT, cropW, cropH);
      final dstRect = Rect.fromLTWH(0, 0, cropW, cropH);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, dstRect);
      canvas.drawImageRect(
        image,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final cropped =
          await picture.toImage(cropW.toInt(), cropH.toInt());

      final byteData =
          await cropped.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      cropped.dispose();

      if (byteData == null) return original;

      final croppedFile = File(
        '${original.parent.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await croppedFile.writeAsBytes(byteData.buffer.asUint8List());
      return croppedFile;
    } on Exception {
      // If cropping fails for any reason, fall back to the full image
      return original;
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (xFile != null) {
      setState(() => _capturedFile = File(xFile.path));
    }
  }

  Future<void> _usePhoto() async {
    if (_capturedFile == null) return;
    setState(() => _isProcessing = true);
    await widget.onCapture(_capturedFile!);
    if (mounted) setState(() => _isProcessing = false);
  }

  void _retake() => setState(() => _capturedFile = null);

  @override
  Widget build(BuildContext context) {
    if (_capturedFile != null) {
      return _PreviewView(
        file: _capturedFile!,
        isProcessing: _isProcessing,
        onUse: _usePhoto,
        onRetake: _retake,
      );
    }

    if (!_hasPermission) {
      return _PermissionDeniedView(
        permanent: _permissionDeniedForever,
        onRetry: _checkPermission,
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          CameraPreview(_controller!),

          // Overlay with frame
          _ScanOverlay(mode: widget.mode),

          // Top controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(RSSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.onCancel != null)
                    IconButton(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    )
                  else
                    const SizedBox(width: 48),
                  IconButton(
                    onPressed: _toggleTorch,
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom: instruction + capture button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: RSSpacing.xl),
                    padding: const EdgeInsets.symmetric(
                      horizontal: RSSpacing.md,
                      vertical: RSSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(RSRadius.md),
                    ),
                    child: Text(
                      widget.instruction,
                      textAlign: TextAlign.center,
                      style: RSTypography.bodyMedium.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: RSSpacing.xl),

                  // Capture button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery picker
                      IconButton(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library_outlined,
                            color: Colors.white, size: 32),
                      ),

                      // Shutter
                      GestureDetector(
                        onTap: _isProcessing ? null : _capture,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            color: _isProcessing
                                ? Colors.white38
                                : Colors.white24,
                          ),
                          child: _isProcessing
                              ? const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 36),
                        ),
                      ),

                      const SizedBox(width: 56), // Balance layout
                    ],
                  ),
                  const SizedBox(height: RSSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Semi-transparent overlay with document frame
class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay({required this.mode});
  final DocumentScannerMode mode;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isVehicle = mode == DocumentScannerMode.vehiclePhoto;
    final frameW = size.width * (isVehicle ? 0.92 : 0.88);
    final frameH = isVehicle ? frameW * 0.6 : frameW * 0.63;

    return CustomPaint(
      size: size,
      painter: _OverlayPainter(frameWidth: frameW, frameHeight: frameH),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter({required this.frameWidth, required this.frameHeight});
  final double frameWidth;
  final double frameHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final frameLeft = (size.width - frameWidth) / 2;
    final frameTop = (size.height - frameHeight) / 2;
    final frameRect =
        Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Punch out frame from overlay
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Draw corner brackets
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cornerLength = 24.0;
    final corners = [
      [frameLeft, frameTop, 1.0, 1.0],
      [frameLeft + frameWidth, frameTop, -1.0, 1.0],
      [frameLeft, frameTop + frameHeight, 1.0, -1.0],
      [frameLeft + frameWidth, frameTop + frameHeight, -1.0, -1.0],
    ];
    for (final c in corners) {
      final x = c[0], y = c[1], dx = c[2], dy = c[3];
      canvas.drawLine(Offset(x, y), Offset(x + dx * cornerLength, y), cornerPaint);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * cornerLength), cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Preview after capture
class _PreviewView extends StatelessWidget {
  const _PreviewView({
    required this.file,
    required this.isProcessing,
    required this.onUse,
    required this.onRetake,
  });

  final File file;
  final bool isProcessing;
  final VoidCallback onUse;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(file, fit: BoxFit.contain),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(RSSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: RSButton(
                        label: 'Reintentar',
                        variant: RSButtonVariant.secondary,
                        onPressed: isProcessing ? null : onRetake,
                      ),
                    ),
                    const SizedBox(width: RSSpacing.md),
                    Expanded(
                      child: RSButton(
                        label: 'Usar foto',
                        onPressed: isProcessing ? null : onUse,
                        isLoading: isProcessing,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Permission denied state
class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.permanent, required this.onRetry});
  final bool permanent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(RSSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined,
                  size: 64, color: RSColors.textSecondary),
              const SizedBox(height: RSSpacing.lg),
              Text(
                'Se requiere acceso a la cámara',
                textAlign: TextAlign.center,
                style: RSTypography.titleLarge.copyWith(color: RSColors.textPrimary),
              ),
              const SizedBox(height: RSSpacing.md),
              Text(
                permanent
                    ? 'El acceso fue denegado permanentemente. Ve a Configuración para habilitarlo.'
                    : 'Necesitamos acceso a la cámara para escanear tus documentos.',
                textAlign: TextAlign.center,
                style: RSTypography.bodyMedium.copyWith(color: RSColors.textSecondary),
              ),
              const SizedBox(height: RSSpacing.xl),
              RSButton(
                label: permanent ? 'Abrir Configuración' : 'Permitir acceso',
                onPressed: permanent ? openAppSettings : onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
