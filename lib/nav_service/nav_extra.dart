import 'dart:convert';

/// A base class for passing extra data during navigation.
class NavExtra {
  NavExtra(Map<String, dynamic> data) : data = _processData(data);

  final Map<String, dynamic> data;

  static Map<String, dynamic> _processData(Map<String, dynamic> data) {
    if (data.isNotEmpty) {
      final jsonString = jsonEncode(data);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return data;
  }

  Map<String, dynamic> toJson() {
    return data;
  }
}
