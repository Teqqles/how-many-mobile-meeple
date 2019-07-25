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
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Setting &&
              toJson() == other.toJson();

  @override
  int get hashCode => toString().hashCode;
}