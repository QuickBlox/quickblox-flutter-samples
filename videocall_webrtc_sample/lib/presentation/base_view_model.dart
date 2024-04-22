import 'package:flutter/cupertino.dart';

class BaseViewModel extends ChangeNotifier {
  bool _loading = false;

  bool get loading => _loading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  void showLoading() {
    if (!_loading) {
      _loading = true;
      notifyListeners();
    }
  }

  void hideLoading() {
    if (_loading) {
      _loading = false;
      notifyListeners();
    }
  }

  void showError(String errorMessage) {
    _errorMessage = errorMessage;
    notifyListeners();
  }

  void hideError() {
    _errorMessage = null;
    notifyListeners();
  }
}
