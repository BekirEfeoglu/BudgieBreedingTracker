/// Milestone types for incubation tracking.
enum MilestoneType { candling, check, sensitive, hatch, late }

/// Represents a key milestone during the incubation period.
class IncubationMilestone {
  final int day;
  final String title;
  final String description;
  final MilestoneType type;
  final DateTime date;
  final bool isPassed;

  const IncubationMilestone({
    required this.day,
    required this.title,
    required this.description,
    required this.type,
    required this.date,
    required this.isPassed,
  });
}
