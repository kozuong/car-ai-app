import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/car_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _prefs = SharedPreferences.getInstance();

  Future<void> saveCarToHistory(CarModel car) async {
    try {
      final prefs = await _prefs;
      final historyJson = prefs.getString(AppConstants.historyKey) ?? '[]';
      final history = List<Map<String, dynamic>>.from(
        jsonDecode(historyJson) as List,
      );

      // Add new car at the beginning of the list
      history.insert(0, car.toJson());

      // Keep only the last 50 items
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      await prefs.setString(AppConstants.historyKey, jsonEncode(history));
    } catch (e) {
      print('Error saving car to history: $e');
    }
  }

  Future<List<CarModel>> getHistory() async {
    try {
      final prefs = await _prefs;
      final historyJson = prefs.getString(AppConstants.historyKey) ?? '[]';
      final history = List<Map<String, dynamic>>.from(
        jsonDecode(historyJson) as List,
      );

      return history
          .map((json) => CarModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting history: $e');
      return [];
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(AppConstants.historyKey);
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  Future<void> saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.languageKey, langCode);
  }

  Future<String> getLanguage() async {
    try {
      final prefs = await _prefs;
      return prefs.getString(AppConstants.languageKey) ?? AppConstants.defaultLanguage;
    } catch (e) {
      print('Error getting language: $e');
      return AppConstants.defaultLanguage;
    }
  }

  Future<void> setLanguage(String langCode) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(AppConstants.languageKey, langCode);
    } catch (e) {
      print('Error setting language: $e');
    }
  }
} 