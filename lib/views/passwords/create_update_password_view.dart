import 'package:flutter/material.dart';
import 'package:secure_pass/services/auth/auth_service.dart';
import 'package:secure_pass/utilities/dialogs/cannot_share_empty_password_dialog.dart';
import 'package:secure_pass/utilities/generics/get_arguments.dart';
import 'package:secure_pass/services/cloud/cloud_password.dart';
import 'package:secure_pass/services/cloud/cloud_storage_exceptions.dart';
import 'package:secure_pass/services/cloud/firebase_cloud_storage.dart';
import 'package:share_plus/share_plus.dart';

class CreateUpdatePasswordView extends StatefulWidget {
  const CreateUpdatePasswordView({Key? key}) : super(key: key);

  @override
  _CreateUpdatePasswordViewState createState() => _CreateUpdatePasswordViewState();
}

class _CreateUpdatePasswordViewState extends State<CreateUpdatePasswordView> {
  CloudPassword? _password;
  late final FirebaseCloudStorage _passwordsService;
  late final TextEditingController _textController;

  @override
  void initState() {
    _passwordsService = FirebaseCloudStorage();
    _textController = TextEditingController();
    super.initState();
  }

  void _textControllerListener() async {
    final password = _password;
    if (password == null) {
      return;
    }
    final text = _textController.text;
    await _passwordsService.updatePassword(
      documentId: password.documentId,
      text: text,
    );
  }

  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  Future<CloudPassword> createOrGetExistingPassword(BuildContext context) async {
    final widgetPassword = context.getArgument<CloudPassword>();

    if (widgetPassword != null) {
      _password = widgetPassword;
      _textController.text = widgetPassword.text;
      return widgetPassword;
    }

    final existingPassword = _password;
    if (existingPassword != null) {
      return existingPassword;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final userId = currentUser.id;
    final newPassword = await _passwordsService.createNewPassword(ownerUserId: userId);
    _password = newPassword;
    return newPassword;
  }

  void _deletePasswordIfTextIsEmpty() {
    final password = _password;
    if (_textController.text.isEmpty && password != null) {
      _passwordsService.deletePassword(documentId: password.documentId);
    }
  }

  void _savePasswordIfTextNotEmpty() async {
    final password = _password;
    final text = _textController.text;
    if (password != null && text.isNotEmpty) {
      await _passwordsService.updatePassword(
        documentId: password.documentId,
        text: text,
      );
    }
  }

  @override
  void dispose() {
    _deletePasswordIfTextIsEmpty();
    _savePasswordIfTextNotEmpty();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Password'),
        actions: [
          IconButton(
            onPressed: () async {
              final text = _textController.text;
              if (_password == null || text.isEmpty) {
                await showCannotShareEmptyPasswordDialog(context);
              } else {
                Share.share(text);
              }
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: FutureBuilder(
        future: createOrGetExistingPassword(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setupTextControllerListener();
              return TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Start typing your password...',
                ),
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
