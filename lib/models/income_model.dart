import 'package:hive/hive.dart';

part 'income_model.g.dart';

@HiveType(typeId: 1)
class Income extends HiveObject {
  @HiveField(0)
  double monthlyIncome;

  @HiveField(1)
  DateTime month;

  Income({
    required this.monthlyIncome,
    required this.month,
  });
}
