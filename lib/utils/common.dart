import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void launchLink(Uri url, BuildContext context, ThemeData theme) async {
  {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch link'),
          duration: Duration(seconds: 2),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }
}
