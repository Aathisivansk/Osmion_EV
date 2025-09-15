import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Model for a Well Wisher (user)
class WellWisher {
  final String name;
  final String email;
  final String? profileImageUrl;

  WellWisher({required this.name, required this.email, this.profileImageUrl});

  factory WellWisher.fromJson(Map<String, dynamic> json) {
    return WellWisher(
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

class ManageWellWishersPage extends StatefulWidget {
  const ManageWellWishersPage({super.key});

  @override
  State<ManageWellWishersPage> createState() => _ManageWellWishersPageState();
}

class _ManageWellWishersPageState extends State<ManageWellWishersPage> {
  List<WellWisher> _wellWishers = [];
  bool _isLoading = true;
  final String baseUrl = "http://10.62.58.114:5000";

  @override
  void initState() {
    super.initState();
    _fetchWellWishers();
  }

  Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  Future<void> _fetchWellWishers() async {
    final userEmail = await _getUserEmail();
    if (userEmail == null) return;

    setState(() => _isLoading = true);
    try {
      final response =
      await http.get(Uri.parse('$baseUrl/api/well_wishers/$userEmail'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _wellWishers = (data['well_wishers'] as List)
                .map((w) => WellWisher.fromJson(w))
                .toList();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load well-wishers: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeWisher(String wisherEmail) async {
    final userEmail = await _getUserEmail();
    final response = await http.post(
      Uri.parse('$baseUrl/api/well_wishers/remove'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_email': userEmail, 'wisher_email': wisherEmail}),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Well-wisher removed'),
            backgroundColor: Colors.green),
      );
      _fetchWellWishers(); // Refresh the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to remove: ${json.decode(response.body)['message']}'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _triggerSOS() async {
    final userEmail = await _getUserEmail();
    final response = await http.post(
      Uri.parse('$baseUrl/api/sos/trigger'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_email': userEmail}),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(json.decode(response.body)['message']),
            backgroundColor: Colors.orangeAccent),
      );
    }
  }

  void _showAddWisherDialog() {
    showDialog(
      context: context,
      builder: (context) => AddWisherDialog(onWisherAdded: _fetchWellWishers),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Well Wishers'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _triggerSOS,
              icon: const Icon(Icons.sos, color: Colors.white),
              label: const Text('TRIGGER SOS',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_wellWishers.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No well-wishers added yet.'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _wellWishers.length,
                itemBuilder: (context, index) {
                  final wisher = _wellWishers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: wisher.profileImageUrl != null && wisher.profileImageUrl!.isNotEmpty
                            ? NetworkImage(wisher.profileImageUrl!)
                            : const AssetImage(
                            'assets/default_profile.png')
                        as ImageProvider,
                      ),
                      title: Text(wisher.name),
                      subtitle: Text(wisher.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_remove,
                            color: Colors.redAccent),
                        onPressed: () => _removeWisher(wisher.email),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWisherDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Well-Wisher',
      ),
    );
  }
}

// A new dialog widget for searching and adding users
class AddWisherDialog extends StatefulWidget {
  final VoidCallback onWisherAdded;
  const AddWisherDialog({super.key, required this.onWisherAdded});

  @override
  State<AddWisherDialog> createState() => _AddWisherDialogState();
}

class _AddWisherDialogState extends State<AddWisherDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<WellWisher> _searchResults = [];
  bool _isSearching = false;
  final String baseUrl = "http://10.62.58.114:5000";

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final response =
      await http.get(Uri.parse('$baseUrl/api/users/search?query=$query'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((d) => WellWisher.fromJson(d)).toList();
        });
      }
    } catch (e) {
      // handle error
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _addWisher(String wisherEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email');

    final response = await http.post(
      Uri.parse('$baseUrl/api/well_wishers/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_email': userEmail, 'wisher_email': wisherEmail}),
    );

    if (mounted) {
      final data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message']),
          backgroundColor: response.statusCode == 201 ? Colors.green : Colors.red,
        ),
      );
    }

    if (response.statusCode == 201) {
      widget.onWisherAdded();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Well-Wisher'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name or email',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const CircularProgressIndicator()
            else
              SizedBox(
                height: 200, // Constrain the height of the list
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      onTap: () => _addWisher(user.email),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}