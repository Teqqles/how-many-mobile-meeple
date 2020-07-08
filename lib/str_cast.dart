class StrCast {

  final _val;

  StrCast(this._val);

  int castToInt() {
    if (_val is String) {
      return int.tryParse(_val);
    }
    return _val;
  }

  double castToDouble() {
    if (_val is String) {
      return double.tryParse(_val);
    }
    return _val;
  }

  List<dynamic> castToList() {
    if (_val is String) {
      var result = _val.replaceAll(new RegExp(r'\[|\]'), '').split(',');
      return result.map((val) => val.trim()).toList();
    }
    return _val;
  }

}