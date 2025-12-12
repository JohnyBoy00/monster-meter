# Monster Meter

A mobile app for Android that helps you track your daily Monster Energy drink consumption. Keep tabs on your caffeine intake, spending, and drinking habits with a sleek, dark-themed interface.

## Features

- **Daily Statistics**: View your daily drink count, total caffeine intake, and spending in real-time
- **Quick Logging**: Add drinks with flavor selection, price, and customizable date/time
- **Flavor Management**: Manage your Monster Energy flavors library with images
- **History & Statistics**: View all-time statistics and historical drink logs grouped by date
- **Multi-Currency Support**: Choose from 10 different currencies for price tracking
- **Visual Flavor Display**: See actual Monster Energy can images for each flavor
- **Local Storage**: All data is stored locally using SQLite - your data stays private

## Database Structure

The app uses three main tables:

### Users Table
| Column   | Type | Description          |
|----------|------|----------------------|
| id       | int  | Primary key          |
| username | text | Username             |

### Flavors Table
| Column      | Type | Description               |
|-------------|------|---------------------------|
| id          | int  | Primary key               |
| name        | text | Flavor name               |
| ml          | int  | Volume in milliliters     |
| caffeine_mg | int  | Caffeine content in mg    |
| is_active   | bool | Active/inactive flag      |
| image_path  | text | Path to flavor image      |

### Logs Table
| Column     | Type | Description                    |
|------------|------|--------------------------------|
| id         | int  | Primary key                    |
| user_id    | int  | Foreign key to users           |
| flavor_id  | int  | Foreign key to flavors         |
| price_paid | real | Price paid for the drink       |
| timestamp  | text | Date and time of consumption   |
| notes      | text | Optional notes (reserved)      |

## Tech Stack

- **Framework**: Flutter (Dart)
- **Database**: SQLite (via sqflite package)
- **Date Formatting**: intl package
- **Path Management**: path package
- **Local Preferences**: shared_preferences package

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio or VS Code with Flutter extensions
- Android device or emulator

## Setup Instructions

### 1. Install Flutter

If you haven't already, install Flutter by following the official guide:
https://docs.flutter.dev/get-started/install

### 2. Clone/Navigate to the Project

```bash
cd /path/to/project/monster-meter
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Check Flutter Setup

```bash
flutter doctor
```

Make sure all checks pass (Android toolchain, Android Studio, etc.)

### 5. Connect Your Device or Start Emulator

For a physical device:
- Enable Developer Options and USB Debugging on your Android device
- Connect via USB

For an emulator:
- Open Android Studio > AVD Manager
- Create/start an Android Virtual Device

Verify your device is connected:
```bash
flutter devices
```

### 6. Run the App

```bash
flutter run
```

Or for a release build:
```bash
flutter run --release
```

## Building APK

To build a release APK:

```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

To build an app bundle (for Play Store):

```bash
flutter build appbundle --release
```

## Project Structure

```
lib/
├── main.dart                           # App entry point and theme configuration
├── database/
│   └── database_helper.dart           # SQLite database operations
├── models/
│   ├── user.dart                      # User model
│   ├── flavor.dart                    # Flavor model
│   ├── log.dart                       # Log model
│   └── log_with_flavor.dart          # Combined model for logs with flavor details
├── screens/
│   ├── home_screen.dart               # Main screen with daily stats
│   ├── add_drink_screen.dart          # Screen to log a new drink
│   ├── history_screen.dart            # View all logs and statistics
│   ├── manage_flavors_screen.dart     # Manage flavor library
│   └── settings_screen.dart           # App settings (currency selection)
└── utils/
    └── currency_helper.dart           # Currency formatting utilities
```

## Usage

### Adding a Drink

1. Tap the "Add Drink" floating action button on the home screen
2. Select a flavor from the dropdown (with visual preview)
3. Enter the price you paid
4. Optionally adjust the date/time using the date and time pickers
5. Tap "Save Drink"

### Managing Flavors

1. Tap the drink icon in the app bar
2. Add new flavors with the "Add Flavor" floating action button
3. Edit, activate/deactivate, or delete existing flavors using the menu (three dots)
4. Toggle visibility of inactive flavors with the eye icon in the app bar

### Viewing History

1. Tap the history icon in the app bar
2. View all-time statistics at the top
3. Scroll through drinks grouped by date
4. Delete entries by tapping the delete icon on each entry

### Changing Currency

1. Tap the settings icon in the app bar
2. Select your preferred currency from the list
3. The currency symbol will update throughout the app

## Pre-loaded Flavors

The app comes with these popular Monster Energy flavors pre-configured with images:

- Original Green (500ml, 160mg caffeine)
- Pipeline Punch (500ml, 160mg caffeine)
- Pacific Punch (500ml, 160mg caffeine)
- Rio Punch (500ml, 160mg caffeine)
- Mango Loco (500ml, 160mg caffeine)
- Zero Sugar Ultra (500ml, 140mg caffeine)
- Zero Sugar Ultra Rosa (500ml, 140mg caffeine)
- Aussie Lemonade (500ml, 160mg caffeine)
- Peachy Keen (500ml, 160mg caffeine)
- The Doctor (500ml, 160mg caffeine)
- Lando Norris (500ml, 160mg caffeine)

## Customization

### Changing Theme Colors

Edit the theme in `lib/main.dart`:

```dart
ColorScheme.fromSeed(
  seedColor: const Color(0xFF00FF00), // Change this color
  brightness: Brightness.dark,
),
```

### Adding More Flavors

You can add more default flavors in `lib/database/database_helper.dart` in the `_createDB` method. Make sure to include the `image_path` pointing to an image in the `assets/images/flavors/` directory.

### Adding Flavor Images

1. Place your flavor images in `assets/images/flavors/`
2. Use WebP format for optimal file size
3. Update the `image_path` in the database when creating flavors

## Design Features

- **Modern Dark Theme**: Sleek dark interface with vibrant accent colors
- **Gradient Cards**: Beautiful gradient backgrounds on statistics cards
- **Rounded Corners**: Consistent 20px border radius throughout
- **Visual Hierarchy**: Clear typography and spacing for easy reading
- **Icon-Based Metadata**: Intuitive icons for volume, caffeine, price, and time
- **Responsive Layout**: Optimized for various screen sizes

## Contributing

This is a personal project, but feel free to fork it and customize it for your own use!

## License

This project is for personal use.

## Disclaimer

This app is not affiliated with Monster Energy. Monster Energy is a trademark of Monster Energy Company.
