import 'package:flutter/material.dart';
import 'package:secure_pass/extensions/buildcontext/loc.dart';
import 'package:secure_pass/utilities/dialogs/generic_dialog.dart';

Future<void> showCannotShareEmptyPasswordDialog(BuildContext context) {
  return showGenericDialog<void>(
    context: context,
    title: context.loc.sharing,
    content: context.loc.cannot_share_empty_password_prompt,
    optionsBuilder: () => {
      context.loc.ok: null,
    },
  );
}