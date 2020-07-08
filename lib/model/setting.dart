class Setting {
  final String name;
  dynamic value;
  String header;
  bool enabled;

  Setting(this.name, {this.value, this.header, this.enabled = false});

  toJson() {
    return {'name': name, 'value': value, 'header': header, 'enabled': enabled};
  }

  @override
  String toString() => "$name, $value, $header, $enabled";

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(json['name'],
        value: json['value'], header: json['header'], enabled: json['enabled']);
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