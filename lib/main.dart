import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secure_pass/constants/routes.dart';
import 'package:secure_pass/helpers/loading/loading_screen.dart';
import 'package:secure_pass/services/auth/bloc/auth_bloc.dart';
import 'package:secure_pass/services/auth/bloc/auth_event.dart';
import 'package:secure_pass/services/auth/bloc/auth_state.dart';
import 'package:secure_pass/services/auth/firebase_auth_provider.dart';
import 'package:secure_pass/views/forgot_password_view.dart';
import 'package:secure_pass/views/login_view.dart';
import 'package:secure_pass/views/passwords/create_update_password_view.dart';
import 'package:secure_pass/views/passwords/password_view.dart';
import 'package:secure_pass/views/register_view.dart';
import 'package:secure_pass/views/verify_email_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:secure_pass/utilities/password_generator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(FirebaseAuthProvider()),
        child: const HomePage(),
      ),
      routes: {
        createOrUpdatePasswordRoute: (context) => const CreateUpdatePasswordView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.read<AuthBloc>().add(const AuthEventInitialize());
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isLoading) {
          LoadingScreen().show(
            context: context,
            text: state.loadingText ?? 'Please wait a moment',
          );
        } else {
          LoadingScreen().hide();
        }
      },
      builder: (context, state) {
        if (state is AuthStateLoggedIn) {
          return const PasswordsView();
        } else if (state is AuthStateNeedsVerification) {
          return const VerifyEmailView();
        } else if (state is AuthStateLoggedOut) {
          return const LoginView();
        } else if (state is AuthStateForgotPassword) {
          return const ForgotPasswordView();
        } else if (state is AuthStateRegistering) {
          return const RegisterView();
        } else {
          return const Scaffold(
            body: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}