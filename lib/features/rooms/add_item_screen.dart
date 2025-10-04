import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/scan_session.dart';
import '../../core/state/item_model.dart';

class AddItemScreen extends StatefulWidget {
  final String roomName;

  const AddItemScreen({super.key, required this.roomName});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

enum Unit { inches, centimeters }

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _widthCtrl = TextEditingController();
  final TextEditingController _lengthCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _countCtrl = TextEditingController(text: '1');
  String? _category;
  String? _finish;
  Unit _unit = Unit.inches;

  final List<String> _categories = ['Furniture', 'Appliance', 'Fixture', 'Other'];
  final List<String> _finishes = ['Oak', 'Pine', 'Laminate', 'Metal', 'Unfinished'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _widthCtrl.dispose();
    _lengthCtrl.dispose();
    _heightCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      // Build item and save to session
      final unitStr = _unit == Unit.inches ? 'in' : 'cm';
      final item = ItemModel(
        name: _nameCtrl.text.trim(),
        category: _category,
        finish: _finish,
        width: _widthCtrl.text.trim(),
        length: _lengthCtrl.text.trim(),
        height: _heightCtrl.text.trim(),
        count: int.tryParse(_countCtrl.text.trim()) ?? 1,
        unit: unitStr,
      );

      // Save into session
      ScanSession.instance.addItem(widget.roomName, item);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: 'Add Item'.text.make(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                'Basic info'.text.semiBold.size(16).make(),
                const SizedBox(height: 12),

                // Item name
                'Item Name'.text.semiBold.make(),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Armchair',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter an item name' : null,
                ),
                const SizedBox(height: 16),

                // Category dropdown
                'Category/Type'.text.semiBold.make(),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('Select category')),
                    ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  ],
                  onChanged: (v) => setState(() => _category = v),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),

                const SizedBox(height: 20),

                'Basic info'.text.semiBold.size(16).make(),
                const SizedBox(height: 8),
                'Unit'.text.make(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _unit = Unit.inches),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _unit == Unit.inches ? Colors.black : const Color(0xFFCBD5E1)),
                            color: _unit == Unit.inches ? const Color(0xFFF8FAFC) : Colors.white,
                          ),
                          alignment: Alignment.center,
                          child: 'Inches (in)'.text.semiBold.make(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _unit = Unit.centimeters),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _unit == Unit.centimeters ? Colors.black : const Color(0xFFCBD5E1)),
                            color: _unit == Unit.centimeters ? const Color(0xFFF8FAFC) : Colors.white,
                          ),
                          alignment: Alignment.center,
                          child: 'Centimeters (cm)'.text.semiBold.make(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Dimensions
                'Width'.text.semiBold.make(),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _widthCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. 100in',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                'Length'.text.semiBold.make(),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lengthCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. 100in',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                'Height'.text.semiBold.make(),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _heightCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. 100in',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),

                const SizedBox(height: 12),
                'Count'.text.semiBold.make(),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _countCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),

                const SizedBox(height: 12),
                'Finish'.text.semiBold.make(),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _finish,
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('e.g. Oak')),
                    ..._finishes.map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  ],
                  onChanged: (v) => setState(() => _finish = v),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),

                const SizedBox(height: 24),

                // Bottom actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        child: 'Cancel'.text.semiBold.make(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onSave,
                        child: 'Add'.text.white.semiBold.make(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF020817),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
