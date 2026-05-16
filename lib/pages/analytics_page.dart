import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  DateTime _selectedMonth = DateTime.now();

  String _formatMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return "${months[date.month - 1]} ${date.year}";
  }

  DateTime get _startOfMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month, 1);

  DateTime get _endOfMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final expensesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('expenses');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Analytics",
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: expensesRef
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfMonth),
            )
            .where('date', isLessThan: Timestamp.fromDate(_endOfMonth))
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!.docs;

          double total = 0;
          final Map<String, double> categoryTotals = {};

          for (final doc in expenses) {
            final data = doc.data();
            final amount = (data['amount'] ?? 0).toDouble();
            final category = data['categoryName'] ?? 'Unknown';

            total += amount;
            categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
          }

          final sorted = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // MONTH NAVIGATION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _navBtn(Icons.chevron_left, () => _changeMonth(-1)),

                    Text(
                      _formatMonth(_selectedMonth),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),

                    _navBtn(Icons.chevron_right, () => _changeMonth(1)),
                  ],
                ),

                const SizedBox(height: 30),

                // TOTAL SPENDING CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Total Spending",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "RM ${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // CATEGORY BREAKDOWN
                if (sorted.isEmpty)
                  const Text("No expenses this month")
                else
                  ...sorted.map((entry) {
                    final percent = total == 0
                        ? 0.0
                        : (entry.value / total).clamp(0.0, 1.0);

                    return _categoryProgress(
                      entry.key,
                      percent,
                      "RM ${entry.value.toStringAsFixed(2)}",
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          color: Colors.white,
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF111827)),
      ),
    );
  }

  Widget _categoryProgress(String label, double progress, String amt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Text(amt),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade100,
            color: const Color(0xFF1D9E75),
          ),
        ],
      ),
    );
  }
}
