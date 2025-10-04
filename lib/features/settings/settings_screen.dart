import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
  title: 'Settings'.text.make(),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: 'How to use'.text.xl2.semiBold.make(),
              ),
              const SizedBox(height: 12),
                SizedBox(
                  height: 170,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: 2,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: SizedBox(
                          width: 160,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/image.png',
                                  width: 160,
                                  height: 110,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'How to scan a room',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w600),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // reduced gap between carousel and FAQ
              const SizedBox(height: 8),
              'Frequently Asked Questions'.text.xl2.semiBold.make(),
              const SizedBox(height: 12),

              _faqItem('Why isn\'t my ceiling detected?', 'Ensure the room is well-lit and the camera has a clear view of the ceiling. Try moving to a different position.'),
              const SizedBox(height: 12),
              _faqItem('Why are my measurements inaccurate?', 'Check the object\'s size and ensure it\'s within the app\'s measurement range. Try different lighting.'),
              const SizedBox(height: 12),
              _faqItem('The app keeps crashing.', 'Restart the app and your device. If the issue persists, contact support for further assistance.'),
              const SizedBox(height
              : 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // Placeholder: open email or support flow
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact Support tapped')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF020817),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: 'Contact Support'.text.white.semiBold.size(18).make(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _faqItem(String q, String a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        q.text.semiBold.make(),
        const SizedBox(height: 6),
        a.text.gray600.make(),
      ],
    );
  }
}
