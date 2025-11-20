enum TagColor {
  yellow,
  blue,
  green,
  red,
  purple,
}

extension TagColorExtension on TagColor {
  String get hex {
    switch (this) {
      case TagColor.yellow:
        return '#F5D76E';
      case TagColor.blue:
        return '#74C0FC';
      case TagColor.green:
        return '#8CE99A';
      case TagColor.red:
        return '#FFA8A8';
      case TagColor.purple:
        return '#D0BFFF';
    }
  }

  String get label {
    switch (this) {
      case TagColor.yellow:
        return 'Yellow';
      case TagColor.blue:
        return 'Blue';
      case TagColor.green:
        return 'Green';
      case TagColor.red:
        return 'Red';
      case TagColor.purple:
        return 'Purple';
    }
  }
}

