import 'package:flutter/material.dart';

import '../errors/app_failure.dart';

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showFailure(BuildContext context, Object error) =>
    showMessage(context, AppFailure.from(error).message);
