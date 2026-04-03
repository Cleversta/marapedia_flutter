import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 140, color: Colors.white),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 80,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 4),
                  ),
                  Container(
                    height: 14,
                    width: 200,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  Container(height: 10, width: 120, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  const ShimmerList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      count,
      (_) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: ShimmerCard(),
      ),
    ),
  );
}