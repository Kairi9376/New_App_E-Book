import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/author_model.dart';
import '../../services/api_service.dart';
import 'add_author_screen.dart';
import 'edit_author_screen.dart';

class AuthorManagementScreen extends StatefulWidget {
  const AuthorManagementScreen({super.key});

  @override
  State<AuthorManagementScreen> createState() => _AuthorManagementScreenState();
}

class _AuthorManagementScreenState extends State<AuthorManagementScreen> {
  List<AuthorModel> _authors = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAuthors();
  }

  Future<void> _fetchAuthors() async {
    setState(() => _isLoading = true);
    final rawAuthors = await ApiService.getAuthors();
    if (mounted) {
      setState(() {
        _authors = rawAuthors.map((a) => AuthorModel.fromMap(a)).toList();
        _isLoading = false;
      });
    }
  }

  void _openAddAuthor() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAuthorScreen()),
    ).then((result) {
      if (result == true && mounted) {
        _fetchAuthors();
      }
    });
  }

  void _openEditAuthor(AuthorModel author) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditAuthorScreen(author: author)),
    ).then((result) {
      if (result == true && mounted) {
        _fetchAuthors();
      }
    });
  }

  Future<void> _deleteAuthor(AuthorModel author) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Author?'),
        content: const Text(
            'Books using this author will be moved to default author.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final bool success = await ApiService.deleteAuthor(author.authorId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Author deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchAuthors();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete author'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAuthors = _authors.where((author) {
      if (_searchQuery.isEmpty) return true;
      return author.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Author Management',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'ຣີເຟຣຊ',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchAuthors,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // --- Search Bar ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search author...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // --- Author List ---
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchAuthors,
                    color: AppColors.primary,
                    child: filteredAuthors.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Icon(Icons.person_off_rounded,
                                  size: 48, color: AppColors.textSecondary),
                              SizedBox(height: 8),
                              Center(
                                child: Text('ບໍ່ພົບນັກຂຽນ',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredAuthors.length,
                            itemBuilder: (context, index) {
                              final author = filteredAuthors[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildAuthorCard(author),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddAuthor,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('ເພີ່ມນັກຂຽນ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAuthorCard(AuthorModel author) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              author.name.isNotEmpty ? author.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(author.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  (author.biography != null && author.biography!.isNotEmpty)
                      ? author.biography!
                      : 'No biography',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  author.createdAt != null
                      ? 'Created: ${author.createdAt}'
                      : '',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Action Buttons (Edit + Delete)
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                color: Colors.blueAccent, size: 20),
            tooltip: 'Edit Author',
            onPressed: () => _openEditAuthor(author),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent, size: 20),
            tooltip: 'Delete Author',
            onPressed: () => _deleteAuthor(author),
          ),
        ],
      ),
    );
  }
}
