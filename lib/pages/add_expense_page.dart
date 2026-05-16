import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;

  String? _selectedCategoryId;
  String? _selectedCategoryName;

  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;

  String _selectedPaymentMethod = 'Cash';

  final List<String> _paymentMethods = [
    'Cash',
    'Card',
    'QR',
    'Bank Transfer',
    'E-Wallet',
  ];

  CollectionReference<Map<String, dynamic>> get _categoriesRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('categories');
  }

  CollectionReference<Map<String, dynamic>> get _expensesRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('expenses');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _expensesRef.add({
        'amount': double.parse(_amountController.text.trim()),

        'note': _noteController.text.trim().isEmpty
            ? 'Untitled expense'
            : _noteController.text.trim(),

        'categoryId': _selectedCategoryId,

        'categoryName': _selectedCategoryName,

        'paymentMethod': _selectedPaymentMethod,

        'date': Timestamp.fromDate(_selectedDate),

        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully'),
            backgroundColor: Color(0xFF1D9E75),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save expense: $e')));
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _categoriesRef.snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load categories'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!.docs;

          if (categories.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No categories found.\nCreate categories first.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Form(
              key: _formKey,

              child: Column(
                children: [
                  // Amount Field
                  TextFormField(
                    controller: _amountController,

                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),

                    decoration: InputDecoration(
                      labelText: 'Amount',

                      prefixText: 'RM ',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter amount';
                      }

                      final amount = double.tryParse(value);

                      if (amount == null) {
                        return 'Invalid number';
                      }

                      if (amount <= 0) {
                        return 'Amount must be greater than 0';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,

                    decoration: InputDecoration(
                      labelText: 'Category',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    items: categories.map((doc) {
                      final data = doc.data();

                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(data['name'] ?? 'Unnamed'),
                      );
                    }).toList(),

                    onChanged: (value) {
                      final selectedCategory = categories.firstWhere(
                        (doc) => doc.id == value,
                      );

                      setState(() {
                        _selectedCategoryId = value;

                        _selectedCategoryName = selectedCategory.data()['name'];
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Payment Method Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPaymentMethod,

                    decoration: InputDecoration(
                      labelText: 'Payment Method',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    items: _paymentMethods.map((method) {
                      return DropdownMenuItem<String>(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Note Field
                  TextFormField(
                    controller: _noteController,

                    maxLines: 3,

                    decoration: InputDecoration(
                      labelText: 'Note',

                      hintText: 'Example: Lunch at canteen',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Date Picker
                  InkWell(
                    onTap: _pickDate,

                    borderRadius: BorderRadius.circular(12),

                    child: Container(
                      width: double.infinity,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),

                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),

                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month),

                          const SizedBox(width: 12),

                          Text(
                            _formatDate(_selectedDate),

                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveExpense,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9E75),

                      foregroundColor: Colors.white,

                      minimumSize: const Size(double.infinity, 55),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Save Expense',

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
