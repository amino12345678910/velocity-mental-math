import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keySpeed = 'speed_ms';
  static const String _keyDigits = 'digits';
  static const String _keyLength = 'sequence_length';

  int _speedMs = 1000;
  int _digits = 1;
  int _sequenceLength = 5;

  int get speedMs => _speedMs;
  int get digits => _digits;
  int get sequenceLength => _sequenceLength;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _speedMs = prefs.getInt(_keySpeed) ?? 1000;
    _digits = prefs.getInt(_keyDigits) ?? 1;
    _sequenceLength = prefs.getInt(_keyLength) ?? 5;
    notifyListeners();
  }

  Future<void> setSpeed(int ms) async {
    _speedMs = ms;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySpeed, ms);
  }

  Future<void> setDigits(int count) async {
    _digits = count;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDigits, count);
  }

  Future<void> setSequenceLength(int length) async {
    _sequenceLength = length;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLength, length);
  }
}
