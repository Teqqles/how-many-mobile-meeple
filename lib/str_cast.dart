class StrCast {
  final _val;

  StrCast(this._val);

  int castToInt() {
    if (_val is String) {
      return int.tryParse(_val) ?? 0;
    }
    return _val as int;
  }

  double castToDouble() {
    if (_val is String) {
      return double.tryParse(_val) ?? 0.0;
    }
    return (_val as num).toDouble();
  }

  List<dynamic> castToList() {
    if (_val is String) {
      var result = _val.replaceAll(new RegExp(r'\[|\]'), '').split(',');
      return result.map((val) => val.trim()).toList();
    }
    return _val;
  }

  bool castToBool() {
    if (_val is String) {
      return _val.toLowerCase() == 'true';
    }
    return _val as bool;
  }
}
