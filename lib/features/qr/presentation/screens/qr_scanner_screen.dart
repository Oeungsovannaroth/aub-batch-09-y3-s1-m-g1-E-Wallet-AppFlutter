import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../transaction/data/transaction_api_service.dart';
import '../../../transaction/presentation/screens/send_amount_screen.dart';
import '../../data/khqr_helper.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _torchOn = false;
  bool _scanning = false;
  bool _handlingQr = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      // In tests / headless environments
      if (mounted) setState(() => _torchOn = !_torchOn);
    }
  }

  Future<void> _handleCode(String rawCode) async {
    if (_handlingQr || !mounted) return;
    setState(() => _handlingQr = true);

    final parsed = KhqrHelper.parseKhqrPayload(rawCode);
    final account = parsed.accountId.isNotEmpty ? parsed.accountId : rawCode.trim();

    if (account.isEmpty) {
      if (mounted) {
        setState(() => _handlingQr = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Invalid QR code format.'),
          ),
        );
      }
      return;
    }

    try {
      final info = await TransactionApiService.instance.inquireRecipient(account);
      if (!mounted) return;

      if (info != null) {
        final verifiedName = info['name']?.toString() ?? (parsed.payeeName ?? account);
        final verifiedWallet = info['wallet_number']?.toString() ?? account;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Verified QR: $verifiedWallet ($verifiedName)'),
          ),
        );

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SendAmountScreen(
              receiver: verifiedName,
              receiverWalletNumber: verifiedWallet,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Account "$account" not found on NovaPay network.'),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to verify QR: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _handlingQr = false);
      }
    }
  }

  Future<void> _uploadFromGallery() async {
    if (_scanning || _handlingQr) return;
    setState(() => _scanning = true);

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        setState(() => _scanning = false);
        return;
      }

      final barcodes = await _controller.analyzeImage(image.path);
      if (!mounted) return;
      setState(() => _scanning = false);

      if (barcodes != null && barcodes.barcodes.isNotEmpty) {
        final code = barcodes.barcodes.first.rawValue;
        if (code != null && code.isNotEmpty) {
          await _handleCode(code);
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('No valid KHQR or NovaPay barcode found in selected image.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Could not read image: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Stack(
      children: [
        Positioned.fill(
          child: MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_handlingQr || _scanning) return;
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue;
                if (raw != null && raw.trim().isNotEmpty) {
                  _handleCode(raw.trim());
                  break;
                }
              }
            },
            errorBuilder: (ctx, err) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Camera preview not active\n(${err.errorCode.name})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 248,
            height: 248,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.yellow, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 12,
          child: IconButton(
            tooltip: 'Close scanner',
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
        Positioned(
          top: 20,
          right: 12,
          child: IconButton(
            tooltip: _torchOn ? 'Turn flash off' : 'Turn flash on',
            onPressed: _toggleTorch,
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_outlined,
              color: _torchOn ? AppColors.yellow : Colors.white,
            ),
          ),
        ),
        Positioned(
          bottom: 34,
          left: 24,
          right: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _handlingQr
                    ? 'Verifying account with NovaPay…'
                    : 'Align a NovaPay or KHQR code within the frame',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 220,
                child: YellowButton(
                  label: 'Upload from gallery',
                  icon: Icons.image_outlined,
                  isLoading: _scanning || _handlingQr,
                  onPressed: _uploadFromGallery,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
