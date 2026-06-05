class Setting {
  final String name;
  dynamic value;
  String? header;
  bool enabled;

  Setting(this.name, {this.value, this.header, this.enabled = false});

  toJson() {
    return {'name': name, 'value': value, 'header': header, 'enabled': enabled};
  }

  @override
  String toString() => "$name, $value, $header, $enabled";

  factory Setting.fromJson(Map<String, dynamic> json) {
    // Handle enabled field which might be stored as string
    final enabled = json['enabled'];
    final enabledBool = enabled is String
        ? enabled.toLowerCase() == 'true'
        : (enabled as bool? ?? false);

    return Setting(json['name'],
        value: json['value'], header: json['header'], enabled: enabledBool);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Setting && toString() == other.toString();
  }

  @override
  int get hashCode => toString().hashCode;

  Setting clone() => Setting(this.name,
      value: this.value, header: this.header, enabled: this.enabled);

  /// Type-safe getter for boolean values
  /// Handles string-to-bool conversion automatically
  bool getBool() {
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return value as bool? ?? false;
  }

  /// Type-safe getter for integer values
  /// Handles string-to-int conversion automatically
  int getInt() {
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) {
      return value.toInt();
    }
    return value as int? ?? 0;
  }

  /// Type-safe getter for double values
  /// Handles string-to-double conversion automatically
  double getDouble() {
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    if (value is int) {
      return value.toDouble();
    }
    return (value as num?)?.toDouble() ?? 0.0;
  }

  /// Type-safe getter for list values
  /// Returns empty list if value is not a list
  List<dynamic> getList() {
    if (value is List) {
      return value as List<dynamic>;
    }
    return [];
  }
}
