import 'package:dummy_bank/screens/pay_n_transfer/transactions/demand_draft_page.dart';
import 'package:dummy_bank/screens/pay_n_transfer/transactions/other_bank_transfer_page.dart';
import 'package:dummy_bank/screens/pay_n_transfer/transactions/upi_transfer.dart';
import 'package:flutter/material.dart';
import 'within_bank_transfer_page.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart'; // <-- Add this import
import 'package:dummy_bank/observer.dart';

class TransferTypePage extends StatefulWidget {
  @override
  _TransferTypePageState createState() => _TransferTypePageState();
}

class _TransferTypePageState extends State<TransferTypePage> {
  final List<Map<String, dynamic>> options = [
    {
      'title': 'Within Bank Transfer',
      'icon': Icons.account_balance,
      'screen': WithinBankTransferPage()
    },
    {
      'title': 'Other Bank Transfer',
      'icon': Icons.account_balance_outlined,
      'screen': OtherBankTransferPage()
    },
    {
      'title': 'Demand Draft',
      'icon': Icons.insert_drive_file,
      'screen': DemandDraftPage()
    },
    {
      'title': 'UPI Transfer',
      'icon': Icons.qr_code_scanner,
      'screen': UpiTransferPage()
    },
  ];

  @override
  Widget build(BuildContext context) {
    return RouteAwareWrapper(
      screenName: 'TransferTypePage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'TransferTypePage',
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              "Send Money",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            backgroundColor: Color(0xFF3B5EDF),
            iconTheme: IconThemeData(
              color: Colors.white,
            ),
          ),
          body: ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: options.length,
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemBuilder: (_, index) {
              final item = options[index];
              return InkWell(
                onTap: item['screen'] != null
                    ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item['screen']),
                )
                    : null,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFFE8ECFB),
                        child: Icon(item['icon'], color: Color(0xFF3B5EDF)),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item['title'],
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
