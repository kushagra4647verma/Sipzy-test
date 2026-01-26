import 'package:flutter/material.dart';
import '../../../services/user_service.dart';
import '../../../core/theme/app_theme.dart';

class FriendsTab extends StatelessWidget {
  final List friends;
  final UserService userService;
  final VoidCallback onRefresh;
  final Function(String, {bool isError}) showToast;

  const FriendsTab({
    super.key,
    required this.friends,
    required this.userService,
    required this.onRefresh,
    required this.showToast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionButtons(context),
        Expanded(
          child: friends.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: friends.length,
                  itemBuilder: (_, i) => _FriendCard(friend: friends[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => showToast('Add from contacts coming soon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add from Phone Book',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showFriendSearch(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Search Friends',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          const Text(
            'No friends yet. Start connecting!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showFriendSearch(BuildContext context) async {
    final query = await showDialog<String>(
      context: context,
      builder: (context) {
        String searchText = '';
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Search Friends',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            onChanged: (v) => searchText = v,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter name or phone',
              hintStyle: TextStyle(color: AppTheme.textTertiary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, searchText),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child:
                  const Text('Search', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );

    if (query != null && query.isNotEmpty) {
      try {
        final results = await userService.searchFriends(query);
        if (results.isNotEmpty && context.mounted) {
          _showSearchResults(context, results);
        } else {
          showToast('No users found');
        }
      } catch (e) {
        showToast('Search failed', isError: true);
      }
    }
  }

  void _showSearchResults(BuildContext context, List results) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2A2A2A),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Search Results',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) => _SearchResultCard(
                    person: results[i],
                    userService: userService,
                    onAdd: () {
                      Navigator.pop(context);
                      showToast('Friend added!');
                      onRefresh();
                    },
                    showToast: showToast,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final Map friend;

  const _FriendCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildAvatar(),
        title: Text(
          friend['name'] ?? 'User',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '@${friend['username'] ?? 'user'}',
              style:
                  const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.secondary,
      child: friend['avatar'] != null && friend['avatar'].toString().isNotEmpty
          ? ClipOval(
              child: Image.network(friend['avatar'],
                  width: 48, height: 48, fit: BoxFit.cover))
          : Text(
              friend['name'][0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map person;
  final UserService userService;
  final VoidCallback onAdd;
  final Function(String, {bool isError}) showToast;

  const _SearchResultCard({
    required this.person,
    required this.userService,
    required this.onAdd,
    required this.showToast,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.secondary,
        child: Text(person['name'][0].toUpperCase(),
            style: const TextStyle(color: Colors.white)),
      ),
      title: Text(person['name'], style: const TextStyle(color: Colors.white)),
      subtitle: Text(person['phone'] ?? person['email'] ?? '',
          style: const TextStyle(color: AppTheme.textSecondary)),
      trailing: IconButton(
        icon: const Icon(Icons.person_add, color: AppTheme.primary),
        onPressed: () async {
          final success = await userService.addFriend(person['id'].toString());
          if (success) {
            onAdd();
          } else {
            showToast('Failed to add friend', isError: true);
          }
        },
      ),
    );
  }
}
