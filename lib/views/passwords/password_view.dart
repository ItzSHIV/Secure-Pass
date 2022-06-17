import 'package:flutter/material.dart';
import 'package:secure_pass/constants/routes.dart';
import 'package:secure_pass/enums/menu_action.dart';
import 'package:secure_pass/services/auth/auth_service.dart';
import 'package:secure_pass/services/cloud/cloud_password.dart';
import 'package:secure_pass/services/cloud/firebase_cloud_storage.dart';

extension Count<T extends Iterable> on Stream<T> {
  Stream<int> get getLength => map((event) => event.length);
}

class PasswordsView extends StatefulWidget {
  const PasswordsView({Key? key}) : super(key: key);

  @override
  _PasswordsViewState createState() => _PasswordsViewState();
}

class _PasswordsViewState extends State<PasswordsView> {
  late final FirebaseCloudStorage _passwordsService;
  String get userId => AuthService.firebase().currentUser!.id;

  @override
  void initState() {
    _passwordsService = FirebaseCloudStorage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder(
          stream: _passwordsService.allPasswords(ownerUserId: userId).getLength,
          builder: (context, AsyncSnapshot<int> snapshot) {
            if (snapshot.hasData) {
              final passwordCount = snapshot.data ?? 0;
              final text = context.loc.passwords_title(passwordCount);
              return Text(text);
            } else {
              return const Text('');
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(createOrUpdatePasswordRoute);
            },
            icon: const Icon(Icons.add),
          ),
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogOutDialog(context);
                  if (shouldLogout) {
                    context.read<AuthBloc>().add(
                          const AuthEventLogOut(),
                        );
                  }
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem<MenuAction>(
                  value: MenuAction.logout,
                  child: Text(context.loc.logout_button),
                ),
              ];
            },
          )
        ],
      ),
      body: StreamBuilder(
        stream: _passwordsService.allPasswords(ownerUserId: userId),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            case ConnectionState.active:
              if (snapshot.hasData) {
                final allPasswords = snapshot.data as Iterable<CloudPassword>;
                return PasswordsListView(
                  passwords: allPasswords,
                  onDeletePassword: (password) async {
                    await _passwordsService.deletePassword(documentId: password.documentId);
                  },
                  onTap: (password) {
                    Navigator.of(context).pushNamed(
                      createOrUpdatePasswordRoute,
                      arguments: password,
                    );
                  },
                );
              } else {
                return const CircularProgressIndicator();
              }
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}