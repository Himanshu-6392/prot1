import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PeerLendDashboard - A beautifully designed, highly polished
/// Peer-to-Peer lending and borrowing dashboard in Flutter & Dart.
/// 
/// This widget features soft rounded corners, premium typography,
/// and responsive layouts matching your visual style guidelines.
class PeerLendDashboard extends StatefulWidget {
  const PeerLendDashboard({super.key});

  @override
  State<PeerLendDashboard> createState() => _PeerLendDashboardState();
}

class _PeerLendDashboardState extends State<PeerLendDashboard> {
  // Mock Data & Interactive State
  double totalBalance = 15450.00;
  double walletBalance = 5420.50;
  double totalPaidAmount = 5550.00;
  double totalLoanAmount = 21000.00;
  
  final List<Map<String, dynamic>> recentActivities = [
    {
      'id': 'act-1',
      'title': 'Monthly Instalment Paid',
      'desc': 'Loan ID #3490 - Business Expansion',
      'amount': -450.00,
      'time': '2 hours ago',
      'type': 'payment',
      'status': 'paid'
    },
    {
      'id': 'act-2',
      'title': 'Deposit Confirmed',
      'desc': 'Linked ACH Account *4402',
      'amount': 1500.00,
      'time': 'Yesterday',
      'type': 'deposit',
      'status': 'paid'
    },
    {
      'id': 'act-3',
      'title': 'Campaign Backed',
      'desc': 'Solar Water Pump Kit listing',
      'amount': -250.00,
      'time': '3 days ago',
      'type': 'backing',
      'status': 'paid'
    }
  ];

  final List<Map<String, dynamic>> pendingRequests = [
    {
      'id': 'req-1',
      'title': 'Organic Farms Greenhouse',
      'amount': 5000.00,
      'funded': 3200.00,
      'purpose': 'Agriculture',
      'interest': 8.5
    }
  ];

  // Colors Matching the PeerLend Web Theme
  final Color primaryColor = const Color(0xFF4F46E5); // Elegant Indigo
  final Color secondaryColor = const Color(0xFF059669); // Emerald Green
  final Color backgroundColor = const Color(0xFFF8FAFC); // Slate 50
  final Color cardColor = Colors.white;
  final Color textDark = const Color(0xFF0F172A); // Slate 900
  final Color textMuted = const Color(0xFF64748B); // Slate 500

  void _showDepositDialog() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Wallet Funds',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter virtual deposit amount in USD.',
              style: GoogleFonts.inter(color: textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '\$ ',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(amountController.text);
              if (val != null && val > 0) {
                setState(() {
                  walletBalance += val;
                  recentActivities.insert(0, {
                    'id': DateTime.now().toString(),
                    'title': 'Deposit Confirmed',
                    'desc': 'Direct Ledger Add',
                    'amount': val,
                    'time': 'Just now',
                    'type': 'deposit',
                    'status': 'paid'
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully deposited \$${val.toStringAsFixed(2)}'),
                    backgroundColor: secondaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm'),
          )
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Make Loan Repayment',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remaining Balance: \$${totalBalance.toStringAsFixed(2)}',
              style: GoogleFonts.inter(color: textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '\$ ',
                hintText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: secondaryColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(amountController.text);
              if (val != null && val > 0 && val <= walletBalance) {
                setState(() {
                  walletBalance -= val;
                  totalBalance = (totalBalance - val).clamp(0, double.infinity);
                  totalPaidAmount += val;
                  recentActivities.insert(0, {
                    'id': DateTime.now().toString(),
                    'title': 'Manual Payment Received',
                    'desc': 'Direct Repayment Step',
                    'amount': -val,
                    'time': 'Just now',
                    'type': 'payment',
                    'status': 'paid'
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully paid \$${val.toStringAsFixed(2)}'),
                    backgroundColor: secondaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Insufficient wallet funds or invalid amount'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Pay Now'),
          )
        ],
      ),
    );
  }

  void _showNewRequestDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Post New Loan Request',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Campaign Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (\$)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text;
              final amt = double.tryParse(amountController.text);
              if (title.isNotEmpty && amt != null && amt > 0) {
                setState(() {
                  pendingRequests.add({
                    'id': DateTime.now().toString(),
                    'title': title,
                    'amount': amt,
                    'funded': 0.0,
                    'purpose': 'Community',
                    'interest': 9.0
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Campaign "$title" published to Peer Listings!'),
                    backgroundColor: primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Post Campaign'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progressPercent = totalPaidAmount / totalLoanAmount;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.compare_arrows, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'PeerLend',
              style: GoogleFonts.plusJakartaSans(
                color: textDark,
                fontWeight: FontWeight.extrabold,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Wallet status bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: primaryColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  '\$${walletBalance.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    color: textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Title
            Text(
              'Welcome back, Peer member',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your Debt Portfolio',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                color: textDark,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            // 1. GRADIENT PORTFOLIO CARD (Soft rounded edges, premium curves)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1E1B4B), primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24), // Elegant 24px soft curve
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL LOAN BALANCE',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.indigo[100],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${totalBalance.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEXT PAYMENT DUE',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.indigo[100],
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'OCT 15, 2026',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _showPaymentDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16), // Soft button edge
                          ),
                        ),
                        child: Text(
                          'MAKE PAYMENT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. ACTIVE REQUESTS & REPAYMENT PROGRESS (BENTO GRID - side by side if wide, stacked on mobile)
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 600;
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  children: [
                    // Active Campaigns Card
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: isWide ? 0 : 16, right: isWide ? 8 : 0),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20), // Soft curve
                          border: Border.all(color: Colors.slate[100]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ACTIVE REQUESTS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: textMuted,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Icon(Icons.hourglass_empty, color: primaryColor, size: 16),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${pendingRequests.length} Pending Campaign',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Funding Total: \$${pendingRequests.fold<double>(0, (sum, item) => sum + item['amount']).toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Repayment Progress Bar Card
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(left: isWide ? 8 : 0),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20), // Soft curves
                          border: Border.all(color: Colors.slate[100]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'REPAYMENT PROGRESS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: textMuted,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Icon(Icons.trending_up, color: secondaryColor, size: 16),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Completed',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textDark,
                                  ),
                                ),
                                Text(
                                  '${(progressPercent * 100).toStringAsFixed(0)}%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Linear Progress Indicator with rounded track
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progressPercent,
                                backgroundColor: Colors.slate[100],
                                valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '\$${totalPaidAmount.toStringAsFixed(0)} Paid',
                                style: GoogleFonts.inter(fontSize: 11, color: textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 3. ACTIONS & SERVICES UTILITIES
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showNewRequestDialog,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Post New Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showDepositDialog,
                    icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                    label: const Text('Deposit Funds'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textDark,
                      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 4. RECENT ACTIVITIES LIST (Round Cards, Clear spacing)
            Text(
              'Recent Activities',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentActivities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final activity = recentActivities[index];
                bool isPayment = activity['type'] == 'payment' || activity['type'] == 'backing';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16), // Premium rounded list items
                    border: Border.all(color: Colors.slate[100]!),
                  ),
                  child: Row(
                    children: [
                      // Status Icon box
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isPayment ? Colors.amber[50] : Colors.emerald[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isPayment ? Icons.arrow_outward : Icons.arrow_downward,
                          color: isPayment ? Colors.amber[800] : Colors.emerald[800],
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Text Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['title'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activity['desc'],
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Amount & Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isPayment ? "-" : "+"}\$${activity['amount'].abs().toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isPayment ? Colors.redAccent : secondaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity['time'],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: textMuted,
                            ),
                          ),
                        ],
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
}
