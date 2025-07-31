import 'package:flutter/material.dart';
import 'transaction_success_page.dart';
import 'package:dummy_bank/screens/pin_popup.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/src/phishsafe_tracker_manager.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart';
import 'package:dummy_bank/observer.dart';

class WithinBankTransferPage extends StatefulWidget {
  @override
  _WithinBankTransferPageState createState() => _WithinBankTransferPageState();
}

class _WithinBankTransferPageState extends State<WithinBankTransferPage> {
  final _formKey = GlobalKey<FormState>();
  String accountNumber = '';
  String amount = '';
  String remarks = '';
  String pin = '';

  @override
  void initState() {
    super.initState();
    // Mark transaction start as user enters the page
    PhishSafeTrackerManager().markTransactionStart();
  }

  void _submitTransfer() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // ✅ Show PIN dialog first
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PinPopup(
          onComplete: (enteredPin) {
            // ✅ Record transaction end after successful PIN confirmation
            PhishSafeTrackerManager().markTransactionEnd();

            // ✅ Record within-bank transfer amount ONLY after confirmation
            PhishSafeTrackerManager().recordWithinBankTransferAmount(amount);

            // Proceed to success screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionSuccessPage(
                  accountNumber: accountNumber,
                  amount: amount,
                  remarks: remarks,
                ),
              ),
            );
          },
        ),
      );
    }
  }

  /// Helper to map tap local position to a 3x3 zone string
  String getTapZone(Offset localPosition, Size size) {
    final zoneWidth = size.width / 3;
    final zoneHeight = size.height / 3;

    final col = (localPosition.dx / zoneWidth).floor().clamp(0, 2);
    final row = (localPosition.dy / zoneHeight).floor().clamp(0, 2);

    const zoneMap = {
      0: {0: 'top_left', 1: 'top_center', 2: 'top_right'},
      1: {0: 'middle_left', 1: 'center', 2: 'middle_right'},
      2: {0: 'bottom_left', 1: 'bottom_center', 2: 'bottom_right'},
    };

    return zoneMap[row]?[col] ?? 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (TapDownDetails details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final size = box.size;

        final zone = getTapZone(localPosition, size);

        PhishSafeTrackerManager().recordTapPosition(
          screenName: 'WithinBankTransferPage',
          tapPosition: details.globalPosition,
          tapZone: zone,
        );
      },
      child: RouteAwareWrapper(
        screenName: 'WithinBankTransferPage',
        observer: routeObserver,
        child: GestureWrapper(
          screenName: 'WithinBankTransferPage',
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                "Transfer within Canara Bank",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              backgroundColor: Color(0xFF3B5EDF),
              iconTheme: IconThemeData(
                color: Colors.white,
              ),
            ),
            body: Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField(
                      label: "Beneficiary Account Number",
                      hint: "Enter account number",
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      onSaved: (val) => accountNumber = val ?? '',
                    ),
                    _buildField(
                      label: "Amount",
                      hint: "Enter amount",
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        final n = num.tryParse(val);
                        if (n == null || n <= 0) return 'Enter a valid amount';
                        return null;
                      },
                      onSaved: (val) => amount = val ?? '',
                    ),
                    _buildField(
                      label: "Remarks",
                      hint: "Remarks (optional)",
                      keyboardType: TextInputType.text,
                      validator: null,
                      onSaved: (val) => remarks = val ?? '',
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3B5EDF),
                        minimumSize: Size(double.infinity, 48),
                      ),
                      child: Text(
                        "Proceed to Transfer",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextInputType keyboardType,
    required FormFieldValidator<String>? validator,
    required Function(String?) onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}
