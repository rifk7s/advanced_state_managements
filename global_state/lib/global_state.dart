import 'package:flutter/material.dart';

/// Static color palette for consistent counter theming
const List<Color> kCounterPalette = [
  Color(0xFFF44336), // red 500
  Color(0xFFE91E63), // pink 500
  Color(0xFF9C27B0), // purple 500
  Color(0xFF673AB7), // deepPurple 500
  Color(0xFF3F51B5), // indigo 500
  Color(0xFF2196F3), // blue 500
  Color(0xFF00BCD4), // cyan 500
  Color(0xFF00ACC1), // teal-ish (approx)
];

class Counter {
  Counter({required this.id, this.value = 0, String? label, Color? color})
    : label = label ?? 'Counter',
      // Deterministic color assignment based on ID hash
      color =
          color ?? kCounterPalette[id.hashCode.abs() % kCounterPalette.length];

  final String id;
  int value;
  String label;
  Color color;
}

class GlobalState extends ChangeNotifier {
  GlobalState();

  final List<Counter> _counters = [];

  List<Counter> get counters => List.unmodifiable(_counters);

  void addCounter({
    String? id,
    int initialValue = 0,
    String? label,
    Color? color,
  }) {
    final counterId = id ?? DateTime.now().microsecondsSinceEpoch.toString();
    _counters.add(
      Counter(id: counterId, value: initialValue, label: label, color: color),
    );
    notifyListeners();
  }

  bool removeCounterById(String id) {
    final before = _counters.length;
    _counters.removeWhere((c) => c.id == id);
    final removed = _counters.length != before;
    if (removed) notifyListeners();
    return removed;
  }

  bool increment(String id) {
    final idx = _counters.indexWhere((c) => c.id == id);
    if (idx == -1) return false;
    _counters[idx].value++;
    notifyListeners();
    return true;
  }

  bool decrement(String id) {
    final idx = _counters.indexWhere((c) => c.id == id);
    if (idx == -1) return false;
    // Prevent negative values
    if (_counters[idx].value > 0) _counters[idx].value--;
    notifyListeners();
    return true;
  }

  /// Update label and/or color for a counter.
  bool updateCounter(String id, {String? label, Color? color}) {
    final idx = _counters.indexWhere((c) => c.id == id);
    if (idx == -1) return false;
    if (label != null) _counters[idx].label = label;
    if (color != null) _counters[idx].color = color;
    notifyListeners();
    return true;
  }

  /// Move a counter from oldIndex to newIndex in the list.
  /// Handles ReorderableListView's drag-and-drop logic
  bool moveCounter(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _counters.length) return false;
    if (newIndex < 0 || newIndex > _counters.length) return false;
    final c = _counters.removeAt(oldIndex);
    // Adjust index after removal for ReorderableListView behavior
    final insertIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    _counters.insert(insertIndex, c);
    notifyListeners();
    return true;
  }
}
