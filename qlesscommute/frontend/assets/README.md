# QLessCommute Assets

This directory contains all the static assets for the QLessCommute Flutter app.

## Directory Structure

### 📷 `images/`
Place your app images here:
- App logo (`app_logo.png`)
- Splash screen images
- Background images
- Illustrations
- Photos

**Recommended formats**: PNG, JPG, WebP
**Recommended sizes**: Multiple resolutions (1x, 2x, 3x)

### 🎨 `icons/`
Place your custom icons here:
- Navigation icons
- Feature icons
- Status icons
- Custom UI icons

**Recommended format**: SVG, PNG
**Recommended sizes**: 24dp, 48dp, 72dp

### 🎬 `animations/`
Place your animation files here:
- Lottie animations (`.json`)
- GIF animations
- Loading animations
- Success/error animations

**Recommended formats**: Lottie JSON, GIF

### 🔤 `fonts/`
Place your custom fonts here:
- Inter (Regular, Bold, Medium)
- Poppins (if needed)
- Any other custom fonts

**Recommended formats**: TTF, OTF

## Adding Assets

1. **Add files** to the appropriate directory
2. **Update pubspec.yaml** to reference the assets:
   ```yaml
   flutter:
     assets:
       - assets/images/
       - assets/icons/
       - assets/animations/
   ```

3. **For fonts**, uncomment and update the fonts section:
   ```yaml
   fonts:
     - family: Inter
       fonts:
         - asset: assets/fonts/Inter-Regular.ttf
         - asset: assets/fonts/Inter-Bold.ttf
           weight: 700
   ```

## Usage in Code

### Images
```dart
Image.asset('assets/images/app_logo.png')
```

### Icons
```dart
Image.asset('assets/icons/home_icon.png')
```

### Fonts
```dart
TextStyle(
  fontFamily: 'Inter',
  fontWeight: FontWeight.bold,
)
```

## Notes

- Keep file sizes optimized for mobile
- Use vector formats (SVG) when possible for icons
- Provide multiple resolutions for bitmap images
- Follow naming conventions: `snake_case.extension`