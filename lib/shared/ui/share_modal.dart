import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_theme.dart';

class ShareModal extends StatelessWidget {
  final VoidCallback onClose;
  final Map<String, dynamic> item;

  const ShareModal({
    super.key,
    required this.onClose,
    required this.item,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: item['url'] ?? ''));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.card,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: AppTheme.textTertiary),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Item preview (title + price)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'Item',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item['subtitle'] ?? ''} • ₹${item['price'] ?? ''}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Share options grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _shareTile(
                  icon: FontAwesomeIcons.whatsapp,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {},
                ),
                _shareTile(
                  icon: FontAwesomeIcons.facebookF,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () {},
                ),
                _shareTile(
                  icon: FontAwesomeIcons.xTwitter,
                  label: 'Twitter',
                  color: Colors.white,
                  onTap: () {},
                ),
                _shareTile(
                  icon: FontAwesomeIcons.instagram,
                  label: 'Instagram',
                  color: const Color(0xFFE4405F),
                  onTap: () {},
                ),
                _shareTile(
                  icon: FontAwesomeIcons.envelope,
                  label: 'Email',
                  color: const Color(0xFF6B7280),
                  onTap: () {},
                ),
                _shareTile(
                  icon: FontAwesomeIcons.link,
                  label: 'Copy Link',
                  color: AppTheme.primary,
                  onTap: () => _copyToClipboard(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
