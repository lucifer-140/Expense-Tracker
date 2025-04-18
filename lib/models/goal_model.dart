import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 2)
class Goal extends HiveObject {
  @HiveField(0)
  double savingTarget; // Can be percentage or fixed amount

  @HiveField(1)
  bool isPercentage;

  @HiveField(2)
  DateTime month;

  Goal({
    required this.savingTarget,
    required this.isPercentage,
    required this.month,
  });
}
