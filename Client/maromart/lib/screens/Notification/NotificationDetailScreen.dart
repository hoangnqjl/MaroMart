import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maromart/components/TopBarSecond.dart';
import 'package:maromart/models/Notification/Notification.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const TopBarSecond(title: 'Notification Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER INFO (Type & Date) ---
            Row(
              children: [
                _buildTypeBadge(notification.type),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- TITLE ---
            Text(
              notification.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'QuickSand',
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),

            // --- CONTENT SECTION ---
            _buildSectionTitle("Message Content"),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA), // Light grey background like AddProduct inputs
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                notification.content,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.6,
                  fontFamily: 'QuickSand',
                ),
              ),
            ),

            // --- EXTRA DATA (Optional) ---
            if (notification.relatedUrl != null && notification.relatedUrl!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle("Related Link"),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // TODO: Implement URL launcher or navigation if needed
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(HeroiconsOutline.link, color: Colors.blue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          notification.relatedUrl!,
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Add more sections from 'data' map if needed
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[800],
        fontWeight: FontWeight.bold,
        fontFamily: 'QuickSand',
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color bgColor;
    Color textColor;
    String text = type.toUpperCase();

    switch (type.toLowerCase()) {
      case 'success':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'warning':
      case 'product_refusal':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      case 'new':
      case 'message':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        break;
      case 'info':
      case 'report':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFEF6C00);
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
