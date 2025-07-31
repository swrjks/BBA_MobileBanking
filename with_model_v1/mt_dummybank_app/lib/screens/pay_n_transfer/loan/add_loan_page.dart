import 'package:flutter/material.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart'; // <-- Add this import
import 'package:dummy_bank/observer.dart';

class AddLoanPage extends StatefulWidget {
  final IconData Function(String type) getIconForLoanType;
  AddLoanPage({required this.getIconForLoanType});
  @override
  _AddLoanPageState createState() => _AddLoanPageState();
}

class _AddLoanPageState extends State<AddLoanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String? _selectedLoanType;
  double? _interestRate;
  double? _remainingAmount;

  final Map<String, double> loanTypes = {
    'Home Loan': 9.25,
    'Student Loan': 8.10,
    'Personal Loan': 10.75,
    'Vehicle Loan': 8.20,
  };

  void _updateCalculation() {
    if (_selectedLoanType != null &&
        _amountController.text.isNotEmpty &&
        _durationController.text.isNotEmpty) {
      final double principal = double.tryParse(_amountController.text) ?? 0.0;
      final double rate = _interestRate ?? 0.0;
      final double time = double.tryParse(_durationController.text) ?? 0.0;
      final double simpleInterest = (principal * rate * time) / 100;
      setState(() {
        _remainingAmount = principal + simpleInterest;
      });
    } else {
      setState(() {
        _remainingAmount = null;
      });
    }
  }

  void _addLoan() {
    if (_formKey.currentState!.validate() && _selectedLoanType != null) {
      final double principal = double.parse(_amountController.text);
      final double rate = _interestRate!;
      final double time = double.parse(_durationController.text);
      final double simpleInterest = (principal * rate * time) / 100;
      final double remaining = principal + simpleInterest;

      final newLoan = {
        'id': DateTime.now().toString(),
        'type': _selectedLoanType,
        'amount': '₹${principal.toStringAsFixed(2)}',
        'interest': '${rate.toStringAsFixed(2)}%',
        'duration': '${time.toStringAsFixed(0)} years',
        'remaining': '₹${remaining.toStringAsFixed(2)}',
        'icon': widget.getIconForLoanType(_selectedLoanType!),
      };
      Navigator.of(context).pop(newLoan);
    }
  }

  Widget _buildGreenButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(label, style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwareWrapper(
      screenName: 'AddLoanPage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'AddLoanPage',
        child: Scaffold(
          appBar: AppBar(
            title: Text("Add New Loan", style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF3B5EDF),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedLoanType,
                    decoration: InputDecoration(
                      labelText: "Loan Type",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items: loanTypes.keys.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLoanType = value;
                        _interestRate = value != null ? loanTypes[value] : null;
                      });
                      _updateCalculation();
                    },
                    validator: (value) => value == null ? 'Please select a loan type' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: "Loan Amount",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    onChanged: (_) => _updateCalculation(),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: "Duration (in years)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    onChanged: (_) => _updateCalculation(),
                  ),
                  SizedBox(height: 16),
                  if (_interestRate != null)
                    TextFormField(
                      enabled: false,
                      initialValue: "${_interestRate!.toStringAsFixed(2)}%",
                      decoration: InputDecoration(
                        labelText: "Interest Rate",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  SizedBox(height: 16),
                  if (_remainingAmount != null)
                    TextFormField(
                      enabled: false,
                      initialValue: "₹${_remainingAmount!.toStringAsFixed(2)}",
                      decoration: InputDecoration(
                        labelText: "Remaining Amount",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
                    ),
                  // Add Button (Green)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _addLoan,
                      child: Text("Add", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(height: 12),
                  // Cancel Button (White with green border and green text)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green[700]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
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
}
