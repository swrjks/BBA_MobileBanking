class InputTracker {
  String? lastTransactionAmount;
  bool fdBroken = false;
  bool loanTaken = false; // ✅ Track loan application

  void setTransactionAmount(String amount) {
    lastTransactionAmount = amount;
  }

  String? getTransactionAmount() => lastTransactionAmount;

  void markFDBroken() {
    fdBroken = true;
  }

  bool get isFDBroken => fdBroken;

  void markLoanTaken() {
    loanTaken = true;
  }

  bool get isLoanTaken => loanTaken;

  void reset() {
    lastTransactionAmount = null;
    fdBroken = false;
    loanTaken = false;
  }
}
