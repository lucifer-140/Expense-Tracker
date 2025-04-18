// date_utils.dart

String getMonthKey(DateTime date) {
  return "${date.year}-${date.month.toString().padLeft(2, '0')}";
}

String formatDateToMonth(DateTime date) {
  // Return a more readable month format, like "April 2025"
  final months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return "${months[date.month - 1]} ${date.year}";
}
