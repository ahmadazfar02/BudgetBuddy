import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final user = FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get _categoriesRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('categories');
  }

  final List<Color> categoryColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  Future<void> _showCategoryDialog({
    String? docId,
    String initialName = '',
    double initialLimit = 0,
    int initialColor = 0xFF1D9E75,
  }) async {
    final nameController = TextEditingController(text: initialName);
    final limitController = TextEditingController(
      text: initialLimit > 0 ? initialLimit.toString() : '',
    );

    int selectedColor = initialColor;

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        docId == null ? 'Create Category' : 'Edit Category',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),

                      const SizedBox(height: 24),

                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Category Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter category name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      TextFormField(
                        controller: limitController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Monthly Limit',
                          prefixText: 'RM ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter monthly limit';
                          }

                          final limit = double.tryParse(value);

                          if (limit == null || limit < 0) {
                            return 'Enter valid amount';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Category Color',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: categoryColors.map((color) {
                          final isSelected = selectedColor == color.value;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedColor = color.value;
                              });
                            },
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final data = {
                            'name': nameController.text.trim(),
                            'monthlyLimit': double.parse(
                              limitController.text.trim(),
                            ),
                            'color': selectedColor,
                            'createdAt': FieldValue.serverTimestamp(),
                          };

                          try {
                            if (docId == null) {
                              await _categoriesRef.add(data);
                            } else {
                              await _categoriesRef.doc(docId).update(data);
                            }

                            if (mounted) {
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    docId == null
                                        ? 'Category created'
                                        : 'Category updated',
                                  ),
                                  backgroundColor: const Color(0xFF1D9E75),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error saving category: $e'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D9E75),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          docId == null ? 'Create Category' : 'Save Changes',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteCategory(String docId) async {
    await _categoriesRef.doc(docId).delete();
  }

  String _formatMoney(double amount) {
    return 'RM ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1D9E75),
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _categoriesRef
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load categories'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No categories yet.\nTap + to create one.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final name = data['name'] ?? 'Unnamed';
              final limit = (data['monthlyLimit'] as num?)?.toDouble() ?? 0;

              final colorValue = data['color'] ?? const Color(0xFF1D9E75).value;

              return Dismissible(
                key: ValueKey(doc.id),

                direction: DismissDirection.endToStart,

                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),

                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Delete Category?'),
                            content: const Text(
                              'This category will be removed.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      ) ??
                      false;
                },

                onDismissed: (_) async {
                  await _deleteCategory(doc.id);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category deleted')),
                    );
                  }
                },

                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),

                    leading: CircleAvatar(
                      backgroundColor: Color(colorValue),
                      child: const Icon(Icons.category, color: Colors.white),
                    ),

                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),

                    subtitle: Text(
                      'Monthly Limit: ${_formatMoney(limit)}',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),

                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        _showCategoryDialog(
                          docId: doc.id,
                          initialName: name,
                          initialLimit: limit,
                          initialColor: colorValue,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
