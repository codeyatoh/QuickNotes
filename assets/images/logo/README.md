# Logo Assets

Place your logo files in this directory.

## Supported Formats
- `.png` (recommended for transparency)
- `.jpg` / `.jpeg`
- `.svg` (requires flutter_svg package)

## Usage

1. Add your logo file to this directory (e.g., `quicknotes_logo.png`)
2. Update `lib/utils/constants.dart` with the correct filename
3. Use `AssetImage` or `Image.asset()` in your code:

```dart
Image.asset(AppConstants.logoAssetPath)
```

## Example

If your logo file is named `quicknotes_logo.png`, the path would be:
```
assets/images/logo/quicknotes_logo.png
```

And in `constants.dart`:
```dart
static const String logoAssetPath = 'assets/images/logo/quicknotes_logo.png';
```

