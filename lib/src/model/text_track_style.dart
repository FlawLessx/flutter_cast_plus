class TextTrackStyle {
  String? backgroundColor;
  String? edgeColor;
  String? edgeType;
  String? fontGenericFamily;
  double? fontScale;
  String? fontStyle;
  String? foregroundColor;
  String? windowColor;
  double? windowRoundedCornerRadius;
  String? windowType;

  TextTrackStyle({
    this.backgroundColor,
    this.edgeColor,
    this.edgeType,
    this.fontGenericFamily,
    this.fontScale,
    this.fontStyle,
    this.foregroundColor,
    this.windowColor,
    this.windowRoundedCornerRadius,
    this.windowType,
  });

  TextTrackStyle.fromCromecastMap(Map<String, dynamic> json) {
    backgroundColor = json['backgroundColor'];
    edgeColor = json['edgeColor'];
    edgeType = json['edgeType'];
    fontGenericFamily = json['fontGenericFamily'];
    fontScale = json['fontScale'];
    fontStyle = json['fontStyle'];
    foregroundColor = json['foregroundColor'];
    windowColor = json['windowColor'];
    windowType = json['windowType'];
    windowRoundedCornerRadius = json['windowRoundedCornerRadius'];
  }

  Map<String, dynamic> toCromecastMap() {
    final data = <String, dynamic>{};
    data['backgroundColor'] = backgroundColor;
    data['edgeColor'] = edgeColor;
    data['edgeType'] = edgeType;
    data['fontGenericFamily'] = fontGenericFamily;
    data['fontScale'] = fontScale;
    data['fontStyle'] = fontStyle;
    data['foregroundColor'] = foregroundColor;
    data['windowColor'] = windowColor;
    data['windowType'] = windowType;
    data['windowRoundedCornerRadius'] = windowRoundedCornerRadius;
    return data;
  }
}
