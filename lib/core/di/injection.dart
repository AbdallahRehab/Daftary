import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

/// Wires every repository, DAO, use case, and Cubit into [getIt]. Nothing in
/// the app self-instantiates a dependency (constitution Principle XIV) —
/// widgets and Cubits always resolve collaborators through this container.
@InjectableInit(preferRelativeImports: true)
Future<void> configureDependencies() async => getIt.init();
