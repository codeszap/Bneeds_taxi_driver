import 'package:flutter/material.dart';


class AppColors {
  static const Color primary = Color(0xFFFFB300); // Darker amber for buttons
  static const Color secondary = Color(0xFFFFECB3); // Soft light yellow for fields
  static const Color link = Color(0xFFFFA000); // Accent for links / highlights
  static const Color background = Color(0xFFFDF6E3); // Soft cream / off-white
  static const Color text = Color(0xFF212121); // Dark text for readability
  static const Color buttonText = Colors.white; // White text on buttons
  static const Color success = Color(0xFF4CAF50); // Green for success actions
  static const Color error = Color(0xFFD32F2F); // Red for errors
  static const Color icon = Color(0xFF757575);
  static const Color online = Colors.green;
  static const Color offline = Colors.redAccent;
  static const Color amber = Colors.amber;
  static const Color rideBusy = Colors.yellow;
  static const Color rideRequestCard = Colors.white;
  static const Color successLight = Color(0xFFDFF2E1); // light green
  static const Color errorLight = Color(0xFFFDECEA); // light red
  static const Color greyText = Color(0xFF757575);
  static const Color infoCardGradientStart = Color(0xFF6DD5FA);
  static const Color infoCardGradientEnd = Color(0xFFFFFFFF);
}


class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.text,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.buttonText,
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.link,
    decoration: TextDecoration.underline,
  );

  static const TextStyle subHeading = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: Colors.black87,
  );

  static const TextStyle important = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: Colors.blueAccent,
  );

  static TextStyle heading({Color color = Colors.black, double size = 20}) {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: size,
      color: color,
    );
  }

  // Content text with optional importance
  static TextStyle content({bool isImportant = false, Color color = Colors.black87, double size = 16, Color? importantColor}) {
    return TextStyle(
      fontSize: size,
      fontWeight: isImportant ? FontWeight.bold : FontWeight.w500,
      color: isImportant ? (importantColor ?? Colors.blueAccent) : color,
    );
  }

  // Button text
  static TextStyle button({Color color = Colors.white, double size = 16}) {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: size,
      color: color,
    );
  }
  }


class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.buttonText,
      elevation: 0,
      titleTextStyle: AppTextStyles.appBarTitle,
    ),
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      background: AppColors.background,
    ),
    textTheme: const TextTheme(
      bodyMedium: AppTextStyles.bodyText,
      labelLarge: AppTextStyles.buttonText,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.buttonText,
        textStyle: AppTextStyles.buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}

class AppDimensions {
  static const double cardRadius = 20.0;
  static const double buttonPadding = 14.0;
  static const double iconPadding = 12.0;
  static const double pagePadding = 16.0;
}
