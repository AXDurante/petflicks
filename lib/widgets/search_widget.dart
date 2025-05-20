import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/search_service.dart';
import '../services/post_service.dart';
import '../widgets/post_widget.dart';
import '../account/profile_page.dart';

class SearchWidget extends StatefulWidget {
  final User? currentUser;
  final PostService postService;

  const SearchWidget({
    super.key,
    required this.currentUser,
    required this.postService,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  List<String> _searchHistory = [];
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('searchHistory') ?? [];
    });
  }

  Future<void> _saveToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _searchHistory.remove(query.trim());
      _searchHistory.insert(0, query.trim());
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('searchHistory', _searchHistory);
  }

  Future<void> _clearSearchHistory() async {
    setState(() {
      _searchHistory.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('searchHistory');
  }

  Widget _buildUserAvatar({String? photoUrl, double radius = 24}) {
    if (photoUrl == null ||
        photoUrl.isEmpty ||
        photoUrl.contains('example.com')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        child: Icon(Icons.person, color: Colors.black, size: radius * 1.2),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(photoUrl),
      backgroundColor: Colors.grey.shade300,
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return const Center(
        child: Text('No recent searches', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: _clearSearchHistory,
                child: const Text(
                  'Clear all',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () async {
                    setState(() {
                      _searchHistory.removeAt(index);
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setStringList('searchHistory', _searchHistory);
                  },
                ),
                onTap: () {
                  _searchController.text = query;
                  setState(() {
                    _searchQuery = query;
                  });
                  _saveToSearchHistory(query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [Tab(text: 'Users'), Tab(text: 'Posts')],
            labelColor: Colors.black,
            indicatorColor: Colors.black,
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Users tab
                FutureBuilder<QuerySnapshot>(
                  future: _searchService.searchUsers(_searchQuery),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No users found'));
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final user = snapshot.data!.docs[index];
                        return ListTile(
                          leading: _buildUserAvatar(
                            photoUrl: user['profile_picture'],
                            radius: 20,
                          ),
                          title: Text(user['name'] ?? 'No name'),
                          subtitle: Text('@${user['username']}'),
                          onTap: () {
                            _saveToSearchHistory(_searchQuery);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ProfilePage(userId: user.id),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                // Posts tab
                FutureBuilder<QuerySnapshot>(
                  future: _searchService.searchPosts(_searchQuery),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No posts found'));
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final post =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                        final postId = snapshot.data!.docs[index].id;
                        return PostWidget(
                          post: post,
                          postId: postId,
                          postService: widget.postService,
                          currentUser: widget.currentUser,
                          timestamp: post['date_created'],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search users or posts...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade200,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 20,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim();
              });
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _saveToSearchHistory(value.trim());
                setState(() {
                  _searchQuery = value.trim();
                });
              }
            },
          ),
        ),
        Expanded(
          child:
              _searchQuery.isEmpty
                  ? _buildSearchHistory()
                  : _buildSearchResults(),
        ),
      ],
    );
  }
}
