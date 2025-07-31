import 'package:flutter/material.dart';
import 'transaction_success_page.dart';
import 'package:dummy_bank/screens/pin_popup.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart'; // <-- Add this import
import 'package:dummy_bank/observer.dart';

class OtherBankTransferPage extends StatefulWidget {
  @override
  _OtherBankTransferPageState createState() => _OtherBankTransferPageState();
}

class _OtherBankTransferPageState extends State<OtherBankTransferPage> {
  final _formKey = GlobalKey<FormState>();
  String accountNumber = '';
  String confirmAccountNumber = '';
  String ifscCode = '';
  String beneficiaryName = '';
  String amount = '';
  String remarks = '';
  String pin = '';

  void _submitTransfer() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (accountNumber != confirmAccountNumber) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account numbers don't match")),
        );
        return;
      }

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
      screenName: 'OtherBankTransferPage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'OtherBankTransferPage',
        child: Scaffold(
          appBar: AppBar(
            title: Text("Transfer to Other Bank",
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
                    label: "Beneficiary Account Number",
                    hint: "Enter account number",
                    keyboardType: TextInputType.number,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                    onSaved: (val) => accountNumber = val!,
                  ),
                  _buildField(
                    label: "Confirm Account Number",
                    hint: "Re-enter account number",
                    keyboardType: TextInputType.number,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                    onSaved: (val) => confirmAccountNumber = val!,
                  ),
                  _buildField(
                    label: "IFSC Code",
                    hint: "Enter 11-digit IFSC",
                    keyboardType: TextInputType.text,
                    validator: (val) => val!.length != 11 ? 'Invalid IFSC' : null,
                    onSaved: (val) => ifscCode = val!,
                  ),
                  _buildField(
                    label: "Beneficiary Name",
                    hint: "Account holder name",
                    keyboardType: TextInputType.name,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                    onSaved: (val) => beneficiaryName = val!,
                  ),
                  _buildField(
                    label: "Amount (₹)",
                    hint: "Enter amount",
                    keyboardType: TextInputType.number,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                    onSaved: (val) => amount = val!,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitTransfer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B5EDF),
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text("Proceed to Transfer",
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
