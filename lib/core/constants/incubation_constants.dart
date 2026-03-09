abstract class IncubationConstants {
  static const int incubationPeriodDays = 18;
  static const int latePeriodDays = 21;
  static const List<String> eggTurningHours = ['08:00', '14:00', '20:00'];
  static const double temperatureMin = 37.0;
  static const double temperatureMax = 38.0;
  static const double temperatureOptimal = 37.5;
  static const double humidityMin = 55.0;
  static const double humidityMax = 65.0;
  static const double humidityOptimal = 60.0;

  // Milestones (day numbers)
  static const int candlingDay = 7;
  static const int secondCheckDay = 14;
  static const int sensitivePeriodDay = 16;
  static const int expectedHatchDay = 18;
  static const int lateHatchDay = 21;
}
