# Flutter Application

This is a Flutter application designed for managing schedules and members. The app includes features such as adding, editing, and managing schedules, as well as member management.

## Features

### Schedule Management
- Add schedules with:
  - Date and time selection.
  - Tags (multiple tags supported).
  - Automatic detection of Sunday (`isSunday` flag).
- Edit schedules and update details.
- View schedules sorted by date and time.

### Member Management
- Add and edit member details:
  - Name.
  - Phone number.
  - Birth date with date picker.

### Firebase Integration
- **Firestore**: Used for storing schedules and member data.
- **Firebase Authentication**: User authentication for secure access.

## Requirements

- **Flutter SDK**: `>=3.0.0`
- **Dart**: `>=2.18.0`
- **Firebase Account**: Ensure Firestore and Authentication are enabled.

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/username/repository-name.git
   cd repository-name
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Add `google-services.json` to `android/app/`.
   - Add `GoogleService-Info.plist` to `ios/Runner/`.

4. Run the app:
   ```bash
   flutter run
   ```

## Folder Structure

```
lib/
├── main.dart                # Entry point of the application
├── screens/                 # Contains all the screens
│   ├── dashboard_screen.dart
│   ├── schedule/
│   │   ├── add_schedule_screen.dart
│   │   ├── edit_schedule_screen.dart
│   │   ├── schedule_management_screen.dart
│   ├── member/
│   │   ├── add_member_screen.dart
│   │   ├── edit_member_screen.dart
│   │   ├── member_management_screen.dart
├── widgets/                 # Reusable widgets
```

## Dependencies

- `firebase_core`: Firebase core integration.
- `firebase_auth`: Firebase authentication.
- `cloud_firestore`: Firestore database.
- `intl`: For date formatting.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch:
   ```bash
   git checkout -b feature-name
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add feature-name"
   ```
4. Push to the branch:
   ```bash
   git push origin feature-name
   ```
5. Open a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.