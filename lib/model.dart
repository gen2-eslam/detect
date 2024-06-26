class BoundingBox {
  final num? x;
  final num? y;
  final num? width;
  final num? height;
  final String? label;
  final num? confidence;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
    required this.confidence,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: json['x'],
      y: json['y'],
      width: json['width'],
      height: json['height'],
      label: json['label'],
      confidence: json['confidence'],
    );
  }
}

class ModelOutput {
  final List<BoundingBox> boxes;

  ModelOutput({required this.boxes});

  factory ModelOutput.fromJson(List<dynamic> json) {
    List<BoundingBox> boxes = [];
    for (int i = 0; i < 4; i++) {
      json[i] = json[i].cast<String, dynamic>();
      boxes.add(BoundingBox.fromJson(json[i]));
    }

    return ModelOutput(boxes: boxes);
  }
}
