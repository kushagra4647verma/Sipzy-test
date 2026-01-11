import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareModal extends StatelessWidget {
  final bool open;
  final VoidCallback onClose;
  final Map<String, dynamic> item;

  const ShareModal({
    super.key,
    required this.open,
    required this.onClose,
    required this.item,
  });

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!open) return const SizedBox.shrink();

    final shareOptions = [
      {
        'name': 'WhatsApp',
        'icon': '💬',
        'color': Colors.green,
        'action': () {
          final text =
              '${item['title']}\n${item['description']}\n${item['url']}';
          _openUrl('https://wa.me/?text=${Uri.encodeComponent(text)}');
        },
      },
      {
        'name': 'Facebook',
        'icon': '📘',
        'color': Colors.blue,
        'action': () {
          _openUrl(
            'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(item['url'])}',
          );
        },
      },
      {
        'name': 'Twitter',
        'icon': '🐦',
        'color': Colors.lightBlue,
        'action': () {
          final text = '${item['title']} - ${item['description']}';
          _openUrl(
            'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}&url=${Uri.encodeComponent(item['url'])}',
          );
        },
      },
      {
        'name': 'Instagram',
        'icon': '📷',
        'color': Colors.pink,
        'action': () {
          _toast(context, 'Please share via Instagram app');
        },
      },
      {
        'name': 'Email',
        'icon': '📧',
        'color': Colors.grey,
        'action': () {
          final subject = Uri.encodeComponent(item['title']);
          final body = Uri.encodeComponent(
            '${item['description']}\n\nCheck it out: ${item['url']}',
          );
          _openUrl('mailto:?subject=$subject&body=$body');
        },
      },
      {
        'name': 'Copy Link',
        'icon': '🔗',
        'color': Colors.purple,
        'action': () {
          Clipboard.setData(ClipboardData(text: item['url']));
          _toast(context, 'Link copied to clipboard!');
          onClose();
        },
      },
    ];

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            const SizedBox(height: 12),
            _itemPreview(),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shareOptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (_, i) {
                final option = shareOptions[i];
                return GestureDetector(
                  onTap: option['action'] as VoidCallback,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: option['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          option['icon'] as String,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        option['name'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI ----------------

  Widget _header() {
    return const Row(
      children: [
        Icon(Icons.share, color: Colors.amber, size: 22),
        SizedBox(width: 8),
        Text(
          'Share',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _itemPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['title'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['description'],
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
