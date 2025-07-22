import 'package:flutter/material.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:dummy_bank/screens/deposits/fixed_deposit_page.dart';
import 'package:dummy_bank/screens/deposits/manage_deposits_page.dart';
import 'package:dummy_bank/screens/pay_n_transfer/loan/loan_page.dart';
import 'package:dummy_bank/screens/pay_n_transfer/transactions/transfer_type_page.dart';
import 'package:dummy_bank/screens/pay_n_transfer/transactions/transaction_history_page.dart';
import 'package:dummy_bank/screens/pay_n_transfer/transactions/upi_transfer.dart';
import 'package:dummy_bank/screens/pay_n_transfer/beneficiaries/beneficiaries_page.dart';
import 'package:dummy_bank/screens/accounts_n_services/card_page.dart';
import 'package:dummy_bank/screens/login_page.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:dummy_bank/observer.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryBlue = Color(0xFF3B5EDF);
  final Color lightBg = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final tracker = PhishSafeTrackerManager();
      tracker.setContext(context);
      tracker.startSession(); // This will handle trust score checking
      print("✅ PhishSafe session started with popup logic.");
    });
  }

  @override
  void dispose() {
    PhishSafeTrackerManager().endSessionAndExport();
    print("🛑 PhishSafe session ended and exported.");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwareWrapper(
      screenName: 'HomePage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'HomePage',
        child: Scaffold(
          backgroundColor: lightBg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: primaryBlue,
                  child: Text('D', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(width: 8),
                Text("Dear Customer", style: TextStyle(color: Colors.black, fontSize: 20)),
              ],
            ),
            actions: [
              IconButton(onPressed: () {}, icon: Icon(Icons.search, color: Colors.black)),
              IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none, color: Colors.black)),
              IconButton(
                onPressed: () async {
                  await PhishSafeTrackerManager().endSessionAndExport();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
                icon: Icon(Icons.power_settings_new, color: Colors.black),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _portfolioCard(),
                SizedBox(height: 16),
                _sectionTitle("Quick Actions"),
                _iconGrid([
                  {
                    'label': 'Send Money',
                    'icon': Icons.send,
                    'action': () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TransferTypePage()));
                    }
                  },
                  {'label': 'Account Summary', 'icon': Icons.account_balance},
                  {'label': 'Pay Bills', 'icon': Icons.receipt},
                  {
                    'label': 'Fixed Deposit',
                    'icon': Icons.savings,
                    'action': () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FixedDepositPage()));
                    }
                  },
                  {'label': 'Rewards', 'icon': Icons.card_giftcard},
                  {'label': 'Recharge', 'icon': Icons.phone_android},
                  {
                    'label': 'Statements',
                    'icon': Icons.insert_drive_file,
                    'action': () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionHistoryPage()));
                    }
                  },
                  {'label': 'Accounts', 'icon': Icons.account_box},
                ]),
                SizedBox(height: 16),
                _promoBanner("Medical Expenses", "Get covered up to 25%", Icons.health_and_safety, Colors.orange),
                SizedBox(height: 16),
                _sectionTitle("Pay & Transfer"),
                _iconGrid([
                  {
                    'label': 'Send Money',
                    'icon': Icons.send,
                    'action': () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TransferTypePage()));
                    }
                  },
                  {
                    'label': 'Direct Pay',
                    'icon': Icons.qr_code_scanner,
                    'action': () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => UpiTransferPage()));
                    }
                  },
                  {'label': 'ePassbook', 'icon': Icons.book},
                  {
                    'label': 'Beneficiaries',
                    'icon': Icons.group,
                    'action': () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BeneficiariesPage()));
                    }
                  },
                ]),
                _iconGrid([
                  {'label': 'Card-less', 'icon': Icons.credit_card_off},
                  {
                    'label': 'Loan',
                    'icon': Icons.currency_rupee,
                    'action': () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => LoanPage()));
                    }
                  },
                  {
                    'label': 'History',
                    'icon': Icons.history,
                    'action': () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionHistoryPage()));
                    }
                  },
                  {'label': 'Manage', 'icon': Icons.settings},
                ]),
                SizedBox(height: 16),
                _promoBanner("Fast UPI Payments", "Convenient cashless transfers", Icons.money, Colors.green),
                SizedBox(height: 16),
                _sectionTitle("Accounts & Services"),
                _iconGrid([
                  {'label': 'Account Summary', 'icon': Icons.account_balance},
                  {'label': 'Passbook', 'icon': Icons.menu_book},
                  {
                    'label': 'Statement',
                    'icon': Icons.description,
                    'action': () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionHistoryPage()));
                    }
                  },
                  {'label': 'Settings', 'icon': Icons.settings},
                ]),
                _iconGrid([
                  {
                    'label': 'Credit Card',
                    'icon': Icons.add_card_rounded,
                    'action': () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CardsPage()));
                    }
                  },
                  {
                    'label': 'Debit Card',
                    'icon': Icons.credit_card,
                    'action': () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CardsPage()));
                    }
                  },
                  {'label': 'Security', 'icon': Icons.security},
                  {'label': 'Calculator', 'icon': Icons.calculate},
                ]),
                SizedBox(height: 16),
                _sectionTitle("Deposits"),
                _iconGrid([
                  {'label': 'FD Calculator', 'icon': Icons.calculate},
                  {'label': 'Deposit History', 'icon': Icons.list_alt},
                  {
                    'label': 'Manage Deposits',
                    'icon': Icons.folder,
                    'action': () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ManageDepositsPage()));
                    }
                  },
                  {'label': 'Certificates', 'icon': Icons.verified},
                ]),
                SizedBox(height: 24),
                _promoBanner("Credit Card", "Get your Pre-Approved Credit Card Now!", Icons.credit_card, primaryBlue),
                SizedBox(height: 32),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: primaryBlue,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              switch (index) {
                case 0:
                  break;
                case 1:
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CardsPage()));
                  break;
                case 2:
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionHistoryPage()));
                  break;
              }
            },
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'All'),
              BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Cards'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Transaction History'),
              BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'ATM'),
              BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );

  Widget _portfolioCard() => Container(
    width: double.infinity,
    padding: EdgeInsets.all(20),
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF3B5EDF), Color(0xFF4C84EF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Text("CB", style: TextStyle(color: Color(0xFF3B5EDF), fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("A/C No: ********4567", style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(height: 4),
                Text("Primary Account", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ],
        ),
        SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildPortfolioItemWithAmount(Icons.account_balance_wallet, "Savings", "₹85,430"),
            _buildPortfolioItemWithAmount(Icons.description, "OD Account", "₹25,000"),
            _buildPortfolioItemWithAmount(Icons.archive, "Deposits", "₹10,000"),
            _buildPortfolioItemWithAmount(Icons.account_balance, "Loans", "₹5,000"),
          ],
        ),
      ],
    ),
  );

  Widget _buildPortfolioItemWithAmount(IconData icon, String label, String amount) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(label, style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          SizedBox(height: 8),
          Text(amount, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );

  Widget _promoBanner(String title, String subtitle, IconData icon, Color color) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 40, color: color),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(subtitle),
          ],
        ),
      ],
    ),
  );

  Widget _iconGrid(List<Map<String, dynamic>> items) => GridView.count(
    crossAxisCount: 4,
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    children: items.map((item) {
      return InkWell(
        onTap: item['action'],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(item['icon'], color: Color(0xFF3B5EDF)),
            ),
            SizedBox(height: 4),
            Text(item['label'], textAlign: TextAlign.center),
          ],
        ),
      );
    }).toList(),
  );
}