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
        other is Setting &&
            toString() == other.toString();
  }

  @override
  int get hashCode => toString().hashCode;

  Setting clone() => Setting(this.name, value: this.value, header: this.header, enabled: this.enabled);
}