import 'package:flutter/material.dart';
import 'transaction_success_page.dart';
import 'package:dummy_bank/screens/pin_popup.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/src/phishsafe_tracker_manager.dart'; // ✅ this one
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

  void _submitTransfer() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // ✅ Track amount entered (this is the only new line)
      PhishSafeTrackerManager().recordTransactionAmount(amount);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PinPopup(
          onComplete: (enteredPin) {
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

  @override
  Widget build(BuildContext context) {
    return RouteAwareWrapper(
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
                    validator: null, // Optional
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
