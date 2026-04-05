import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      color: const Color(0xFFFEF3C7),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 13, color: Color(0xFF92400E)),
          SizedBox(width: 8),
          Text(
            "You're offline — showing cached content",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}