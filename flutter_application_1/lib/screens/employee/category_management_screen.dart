import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/category_model.dart';
import '../../services/api_service.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    final rawCategories = await ApiService.getCategories();
    if (mounted) {
      setState(() {
        _categories =
            rawCategories.map((c) => CategoryModel.fromMap(c)).toList();
        _isLoading = false;
      });
    }
  }

  void _openAddCategory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
    ).then((result) {
      if (result == true && mounted) {
        _fetchCategories();
      }
    });
  }

  void _openEditCategory(CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditCategoryScreen(category: category)),
    ).then((result) {
      if (result == true && mounted) {
        _fetchCategories();
      }
    });
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Category?'),
        content: const Text(
            'Books using this category will lose this category tag.'),
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

    final bool success = await ApiService.deleteCategory(category.categoryId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchCategories();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete category'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _categories.where((category) {
      if (_searchQuery.isEmpty) return true;
      return category.name.toLowerCase().contains(_searchQuery.toLowerCase());
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
                color: const Color(0xFF10B981).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.category_rounded,
                  color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Category Management',
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
            onPressed: _fetchCategories,
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
                      hintText: 'Search category...',
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

                // --- Category List ---
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchCategories,
                    color: AppColors.primary,
                    child: filteredCategories.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              const Icon(Icons.category_outlined,
                                  size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              const Center(
                                child: Text('ບໍ່ພົບໝວດໝູ່',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredCategories.length,
                            itemBuilder: (context, index) {
                              final category = filteredCategories[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildCategoryCard(category),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCategory,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('ເພີ່ມໝວດໝູ່',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
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
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: const Icon(Icons.category_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  category.createdAt != null
                      ? 'Created: ${category.createdAt}'
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
            tooltip: 'Edit Category',
            onPressed: () => _openEditCategory(category),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent, size: 20),
            tooltip: 'Delete Category',
            onPressed: () => _deleteCategory(category),
          ),
        ],
      ),
    );
  }
}
