import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests location permission with rationale copy, gating GPS on the
/// saved photo(s). Denial (or a dismissed rationale) never blocks the
/// save — it just means no lat/lng. Shared by the single-photo and
/// batch-upload flows so a batch only prompts once, not once per photo.
Future<bool> resolveLocationPermission(BuildContext context) async {
  var status = await Permission.location.status;
  if (status.isGranted) return true;
  if (status.isPermanentlyDenied || status.isRestricted) return false;
  if (!context.mounted) return false;

  final shouldAsk = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tag this photo with its location?'),
      content: const Text(
        'Trevy can save where a photo was taken so it shows up in your '
        "journal and wrap-up. You can still add photos without this.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Allow'),
        ),
      ],
    ),
  );
  if (shouldAsk != true) return false;

  status = await Permission.location.request();
  return status.isGranted;
}
