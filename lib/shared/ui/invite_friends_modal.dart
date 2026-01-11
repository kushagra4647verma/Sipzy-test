import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/env_config.dart';

class InviteFriendsModal extends StatefulWidget {
  final bool open;
  final VoidCallback onClose;
  final Map<String, dynamic> user;
  final Map<String, dynamic> restaurant;

  const InviteFriendsModal({
    super.key,
    required this.open,
    required this.onClose,
    required this.user,
    required this.restaurant,
  });

  @override
  State<InviteFriendsModal> createState() => _InviteFriendsModalState();
}

class _InviteFriendsModalState extends State<InviteFriendsModal> {
  static const api = EnvConfig.apiBaseUrl;

  List friends = [];
  List<int> selectedFriends = [];
  String searchQuery = '';
  String message = '';
  bool loading = false;

  @override
  void didUpdateWidget(covariant InviteFriendsModal oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.open && !oldWidget.open) {
      fetchFriends();
      message =
          "Let's visit ${widget.restaurant['name'] ?? 'this place'} together!";
    }
  }

  Future<void> fetchFriends() async {
    try {
      final res = await http.get(
        Uri.parse('$api/friends/${widget.user['id']}'),
      );
      setState(() => friends = jsonDecode(res.body));
    } catch (_) {
      _toast('Failed to load friends');
    }
  }

  void toggleFriend(int id) {
    setState(() {
      if (selectedFriends.contains(id)) {
        selectedFriends.remove(id);
      } else {
        selectedFriends.add(id);
      }
    });
  }

  void handleInvite() {
    if (selectedFriends.isEmpty) {
      _toast('Please select at least one friend');
      return;
    }

    // TODO: integrate ShareModal / share_plus
    _toast('Invite ready to share');
    widget.onClose();
  }

  List get filteredFriends => friends
      .where((f) => f['name'].toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open) return const SizedBox.shrink();

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 12),
              _search(),
              const SizedBox(height: 12),
              Expanded(child: _friendsList()),
              const SizedBox(height: 12),
              _messageBox(),
              const SizedBox(height: 12),
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- UI ----------------

  Widget _header() {
    return const Row(
      children: [
        Icon(Icons.people, color: Colors.purple, size: 22),
        SizedBox(width: 8),
        Text(
          'Invite Friends',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _search() {
    return TextField(
      onChanged: (v) => setState(() => searchQuery = v),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search friends...',
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.search, color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _friendsList() {
    if (filteredFriends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.white24),
            SizedBox(height: 8),
            Text('No friends found', style: TextStyle(color: Colors.white60)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredFriends.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final friend = filteredFriends[i];
        final selected = selectedFriends.contains(friend['id']);

        return GestureDetector(
          onTap: () => toggleFriend(friend['id']),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              border:
                  selected ? Border.all(color: Colors.purple, width: 2) : null,
            ),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  activeColor: Colors.purple,
                  onChanged: (_) => toggleFriend(friend['id']),
                ),
                CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Text(
                    friend['name'][0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '@${friend['name'].toLowerCase().replaceAll(' ', '')}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _messageBox() {
    return TextField(
      minLines: 2,
      maxLines: 4,
      onChanged: (v) => message = v,
      controller: TextEditingController(text: message),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Add a personal message...',
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onClose,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: selectedFriends.isEmpty ? null : handleInvite,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Send Invites'),
          ),
        ),
      ],
    );
  }
}
