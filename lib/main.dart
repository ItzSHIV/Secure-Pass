import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:secure_pass/constants/routes.dart';
import 'package:secure_pass/firebase_options.dart';
import 'package:secure_pass/views/login_view.dart';
import 'package:secure_pass/views/register_view.dart';
import 'package:secure_pass/views/verify_email_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        passwordRoute:(context) => const PasswordView()
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          switch (snapshot.connectionState){
            case ConnectionState.done:
            final user = FirebaseAuth.instance.currentUser;
            if(user != null){
              if(user.emailVerified){
                return const PasswordView();
              } else{
                  return const VerifyEmailView();
              } 
            } else{
              return const LoginView();
            }
            default:
              return const CircularProgressIndicator();
          }  
        },
      );
  }
}

enum MenuAction { logout }

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
                  await FirebaseAuth.instance.signOut();
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