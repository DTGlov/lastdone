// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_driver/driver_extension.dart';

import 'app/bootstrap.dart';

Future<void> main() async {
  enableFlutterDriverExtension();
  await bootstrap();
}
