import 'package:get_it/get_it.dart';
import '../../features/menu/data/menu_repository.dart';
import '../../features/menu/domain/services/cart_service.dart';
import '../../features/schedule/data/schedule_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  if (!getIt.isRegistered<MenuRepository>()) {
    getIt.registerLazySingleton<MenuRepository>(
      () => AssetsMenuRepository(),
    );
  }
  if (!getIt.isRegistered<CartService>()) {
    getIt.registerLazySingleton<CartService>(() => CartService());
  }
  if (!getIt.isRegistered<ScheduleRepository>()) {
    getIt.registerLazySingleton<ScheduleRepository>(
      () => ScheduleRepository(),
    );
  }
}
