import 'dart:async';
import 'package:flutter/material.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:memno/logic/functionality/check_update.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:ota_update/ota_update.dart';
import 'package:provider/provider.dart';

class UpdateBottomSheet extends StatefulWidget {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;

  const UpdateBottomSheet({
    super.key,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  @override
  State<UpdateBottomSheet> createState() => _UpdateBottomSheetState();
}

class _UpdateBottomSheetState extends State<UpdateBottomSheet> {
  bool _isDownloading = false;
  double _progress = 0;
  String _statusMessage = "Ready to download";
  StreamSubscription<OtaEvent>? _otaSubscription;

  @override
  void dispose() {
    _otaSubscription?.cancel();
    super.dispose();
  }

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _statusMessage = "Starting download...";
    });

    try {
      _otaSubscription = startOtaUpdate(widget.downloadUrl).listen(
        (OtaEvent event) {
          setState(() {
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                _progress = double.tryParse(event.value ?? "0") ?? 0;
                _statusMessage = "Downloading: ${_progress.toInt()}%";
                break;
              case OtaStatus.INSTALLING:
                _statusMessage = "Installing update...";
                break;
              case OtaStatus.INSTALLATION_DONE:
                _statusMessage = "Update installed.";
                _isDownloading = false;
                break;
              case OtaStatus.INSTALLATION_ERROR:
                _statusMessage = "Installation failed.";
                _isDownloading = false;
                break;
              case OtaStatus.CHECKSUM_ERROR:
                _statusMessage = "Checksum error. Try again later.";
                _isDownloading = false;
                break;
              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                _statusMessage = "Permission not granted.";
                _isDownloading = false;
                break;
              case OtaStatus.INTERNAL_ERROR:
                _statusMessage = "An internal error occurred.";
                _isDownloading = false;
                break;
              case OtaStatus.DOWNLOAD_ERROR:
                _statusMessage = "File could not be downloaded.";
                _isDownloading = false;
                break;
              case OtaStatus.ALREADY_RUNNING_ERROR:
                _statusMessage = "An update is already in progress.";
                break;
              default:
                _statusMessage = "Something went wrong.";
                _isDownloading = false;
                break;
            }
          });
        },
        onError: (e) {
          setState(() {
            _statusMessage = "Download failed: $e";
            _isDownloading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _statusMessage = "Failed to initialize update: $e";
        _isDownloading = false;
      });
    }
  }

  void _cancelDownload() async {
    try {
      await OtaUpdate().cancel();
      _otaSubscription?.cancel();
      // Ensure cleanup after cancellation
      await cleanupUpdateFiles();
      setState(() {
        _isDownloading = false;
        _progress = 0;
        _statusMessage = "Download cancelled.";
      });
      if (mounted) {
        showToastMsg(context, "Update cancelled");
      }
    } catch (e) {
      debugPrint("Error cancelling download: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: colors.isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Update Available",
                    style: TextStyle(
                      color: colors.textClr,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'GoogleSans',
                    ),
                  ),
                  Text(
                    "Version ${widget.latestVersion}",
                    style: TextStyle(
                      color: colors.textClr.withValues(alpha: 0.6),
                      fontSize: 16,
                      fontFamily: 'GoogleSans',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.accnt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.system_update_alt_rounded,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "What's New:",
            style: TextStyle(
              color: colors.textClr,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'GoogleSans',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.pill,
              borderRadius: BorderRadius.circular(20),
            ),
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Text(
                widget.releaseNotes,
                style: TextStyle(
                  color: colors.textClr,
                  fontSize: 14,
                  fontFamily: 'GoogleSans',
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          if (_isDownloading)
            Column(
              children: [
                LinearProgressIndicator(
                  value: _progress / 100,
                  backgroundColor: colors.box,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accnt),
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 10,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: colors.textClr,
                        fontSize: 14,
                        fontFamily: 'GoogleSans',
                      ),
                    ),
                    TextButton(
                      onPressed: _cancelDownload,
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'GoogleSans',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(18),
                      side: BorderSide(
                        color: colors.textClr.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text(
                      "Not Now",
                      style: TextStyle(
                        color: colors.textClr,
                        fontFamily: 'GoogleSans',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accnt,
                      foregroundColor: colors.accntText,
                      padding: const EdgeInsets.all(18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text(
                      "Update Now",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'GoogleSans',
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
