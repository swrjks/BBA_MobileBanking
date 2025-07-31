class InputTracker {
  String? lastTransactionAmount;
  DateTime? transactionTime;
  DateTime? fdBrokenTime;
  DateTime? loanTakenTime;
  DateTime? loginTime;

  void setTransactionAmount(String amount) {
    lastTransactionAmount = amount;
    transactionTime = DateTime.now();
  }

  String? getTransactionAmount() => lastTransactionAmount;

  void markLogin() {
    loginTime = DateTime.now();
  }

  void markFDBroken() {
    fdBrokenTime = DateTime.now();
  }

  bool get isFDBroken => fdBrokenTime != null;

  void markLoanTaken() {
    loanTakenTime = DateTime.now();
  }

  bool get isLoanTaken => loanTakenTime != null;

  Duration? get timeFromLoginToFD =>
      loginTime != null && fdBrokenTime != null
          ? fdBrokenTime!.difference(loginTime!)
          : null;

  Duration? get timeFromLoginToLoan =>
      loginTime != null && loanTakenTime != null
          ? loanTakenTime!.difference(loginTime!)
          : null;

  Duration? get timeBetweenFDAndLoan =>
      fdBrokenTime != null && loanTakenTime != null
          ? loanTakenTime!.difference(fdBrokenTime!)
          : null;

  void reset() {
    lastTransactionAmount = null;
    transactionTime = null;
    fdBrokenTime = null;
    loanTakenTime = null;
    loginTime = null;
  }
}