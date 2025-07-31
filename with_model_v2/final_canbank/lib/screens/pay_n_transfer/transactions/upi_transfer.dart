import 'package:flutter/material.dart';
import 'transaction_success_page.dart';
import 'package:dummy_bank/screens/pin_popup.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart'; // <-- Add this import
import 'package:dummy_bank/observer.dart';

class UpiTransferPage extends StatefulWidget {
  @override
  _UpiTransferPageState createState() => _UpiTransferPageState();
}

class _UpiTransferPageState extends State<UpiTransferPage> {
  final _formKey = GlobalKey<FormState>();
  String upiId = '';
  String amount = '';
  String remarks = '';

  void _submitTransfer() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PinPopup(
          onComplete: (enteredPin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionSuccessPage(
                  accountNumber: upiId,
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
      screenName: 'UpiTransferPage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'UpiTransferPage',
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              "UPI Transfer",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF3B5EDF),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildField(
                    label: "Recipient UPI ID",
                    hint: "e.g. name@bank",
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      //if (!RegExp(r'^[\w.\-]+@[\w]+$').hasMatch(val)) return 'Invalid UPI ID';
                      return null;
                    },
                    onSaved: (val) => upiId = val!,
                  ),
                  _buildField(
                    label: "Amount (₹)",
                    hint: "Enter amount",
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      final n = num.tryParse(val);
                      if (n == null || n <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onSaved: (val) => amount = val!,
                  ),
                  _buildField(
                    label: "Remarks",
                    hint: "Purpose (optional)",
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
                      style: TextStyle(color: Colors.white, fontSize: 17),
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
    required FormFieldSetter<String> onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        keyboardType: keyboardType,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}
