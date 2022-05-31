import 'package:flutter/material.dart';
import 'package:secure_pass/constants/routes.dart';
import 'package:secure_pass/enums/menu_action.dart';
import 'package:secure_pass/services/auth/auth_service.dart';

class PasswordView extends StatefulWidget {
  const PasswordView({Key? key}) : super(key: key);

  @override
  State<PasswordView> createState() => _PasswordViewState();
}

class _PasswordViewState extends State<PasswordView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Main UI'),
      actions: [
        PopupMenuButton<MenuAction>(
          onSelected: (value) async{
            switch(value){
              case MenuAction.logout:
                final shouldLogout = await showLogOutDialog(context);
                if (shouldLogout){
                  await AuthService.firebase().logOut();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    loginRoute, 
                    (_) => false
                  );
                }
            }
          }, 
          itemBuilder: (context){
            return const [
              PopupMenuItem<MenuAction>(
              value: MenuAction.logout, 
              child: Text('Log out'),
              ),
            ];
        },
        )
      ],
      ),
      body: const Text('Hello World'),
    );
  }
}

Future<bool> showLogOutDialog(BuildContext context){
  return showDialog<bool>(
    context: context, 
    builder: (context) {
    return AlertDialog(
      title: const Text('Log out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () {
          Navigator.of(context).pop(false);
        }, 
        child: const Text('Cancel'),
        ),
        TextButton(onPressed: () {
          Navigator.of(context).pop(true);
        }, 
        child: const Text('Log out'),
        ),
      ],
    );
  },
  ).then((value) => value ?? false) ;
}