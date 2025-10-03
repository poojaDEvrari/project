import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class ScannedRoomsScreen extends StatelessWidget {
  final int totalRooms;
  const ScannedRoomsScreen({super.key, this.totalRooms = 5});

  @override
  Widget build(BuildContext context) {
    final roomList = totalRooms > 0 ? List.generate(totalRooms, (i) => 'Room ${i + 1}') : ['Room 1'];
    final scannedRooms = roomList.take((totalRooms > 3 ? 3 : totalRooms)).toList(); // Take up to 3 or totalRooms

    return Scaffold(
      appBar: AppBar(
        title: 'Scanned Rooms'.text.make(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            ...(() {
              final withSeparators = <Widget>[];
              for (var i = 0; i < scannedRooms.length; i++) {
                withSeparators.add(_ScannedRoomCard(title: scannedRooms[i], status: 'Fully Scanned'));
                if (i < scannedRooms.length - 1) {
                  withSeparators.add(const SizedBox(height: 12));
                }
              }
              return withSeparators;
            })(),
            const SizedBox(height: 16),
            _AddRoomCard(
              onTap: () => context.go('/scan/running?room=Room%201&index=1&total=$totalRooms'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Placeholder for View Room Details
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View Room Details coming soon')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Room Details', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _ScannedRoomCard extends StatelessWidget {
  final String title;
  final String status;
  const _ScannedRoomCard({required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 64,
            height: 48,
            color: const Color(0xFFF1F5F9),
            child: const Icon(Icons.image, color: Colors.black38),
          ),
        ),
        title: title.text.semiBold.make(),
        subtitle: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
            const SizedBox(width: 6),
            status.text.color(const Color(0xFF16A34A)).make(),
          ],
        ),
        trailing: const Icon(Icons.more_horiz),
        onTap: () {},
      ),
    );
  }
}

class _AddRoomCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddRoomCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      dashPattern: const [6, 6],
      color: const Color(0xFFCBD5E1),
      strokeWidth: 1.2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 100,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline, color: Colors.black87),
              const SizedBox(width: 8),
              'Add Room'.text.semiBold.make(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (i) {
        if (i == 0) return; // Home
        if (i == 1) {
          // Settings (placeholder)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings coming soon')),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Setting'),
      ],
    );
  }
}

// Simple dotted border painter to avoid extra package
class DottedBorder extends StatelessWidget {
  final Widget child;
  final BorderType borderType;
  final Radius radius;
  final List<double> dashPattern;
  final Color color;
  final double strokeWidth;

  const DottedBorder({
    super.key,
    required this.child,
    this.borderType = BorderType.RRect,
    this.radius = const Radius.circular(0),
    this.dashPattern = const [4, 4],
    this.color = Colors.black26,
    this.strokeWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        borderType: borderType,
        radius: radius,
        dashPattern: dashPattern,
        color: color,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

enum BorderType { RRect }

class _DottedBorderPainter extends CustomPainter {
  final BorderType borderType;
  final Radius radius;
  final List<double> dashPattern;
  final Color color;
  final double strokeWidth;

  _DottedBorderPainter({
    required this.borderType,
    required this.radius,
    required this.dashPattern,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    _drawDashedRRect(canvas, rrect, paint, dashPattern);
  }

  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint, List<double> dashArray) {
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      bool draw = true;
      int index = 0;
      while (distance < metric.length) {
        final len = dashArray[index % dashArray.length];
        if (draw) {
          final extract = metric.extractPath(distance, (distance + len).clamp(0, metric.length));
          canvas.drawPath(extract, paint);
        }
        distance += len;
        draw = !draw;
        index++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
