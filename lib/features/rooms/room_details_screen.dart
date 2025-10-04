import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/scan_session.dart';

class RoomDetailsScreen extends StatelessWidget {
  final String roomName;

  const RoomDetailsScreen({super.key, required this.roomName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: '$roomName Details'.text.make(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: VStack([
          // Room header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, size: 40, color: Colors.black38),
                ),
                const SizedBox(height: 16),
                roomName.text.semiBold.size(20).make(),
                const SizedBox(height: 8),
                'Fully Scanned'.text.color(const Color(0xFF16A34A)).make(),
              ],
            ),
          ).p16(),

          const SizedBox(height: 24),

          // Room items section
          'Room Items'.text.semiBold.size(18).make(),
          const SizedBox(height: 12),

          // Items list (from session)
          ...(() {
            final items = ScanSession.instance.itemsFor(roomName);
            if (items.isEmpty) {
              return [
                const SizedBox(height: 12),
                'No items added yet'.text.gray500.make(),
                const SizedBox(height: 12),
              ];
            }
            return items.map((it) => _RoomItemCard(
              itemName: it.name,
              category: it.category ?? 'Unknown',
            )).toList();
          })(),

          const SizedBox(height: 16),

          // Add Item button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to the registered route for adding an item
                context.push('/rooms/add?room=${Uri.encodeComponent(roomName)}');
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: 'Add Item'.text.white.semiBold.make(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F80ED),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]).p16(),
      ),
    );
  }
}

class _RoomItemCard extends StatelessWidget {
  final String itemName;
  final String category;

  const _RoomItemCard({
    required this.itemName,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Colors.black38),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: VStack([
              itemName.text.semiBold.make(),
              const SizedBox(height: 4),
              category.text.color(Colors.grey).make(),
            ]),
          ),
          const Icon(Icons.more_vert),
        ],
      ),
    );
  }
}
