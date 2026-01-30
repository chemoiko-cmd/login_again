import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/maintenance_cubit.dart';
import 'cubit/maintenance_state.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  @override
  void initState() {
    super.initState();

    // Get the partner ID from AuthCubit
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      print('the partner id is: ${authState.user.partnerId}');
      context.read<MaintenanceCubit>().loadRequests(authState.user.partnerId);
    }
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<MaintenanceCubit, MaintenanceState>(
        listener: (context, state) {
          if (state is MaintenanceLoading) {
            loading.Widgets.showLoader(context);
          } else {
            loading.Widgets.hideLoader(context);
          }
        },
        builder: (context, state) {
          if (state is MaintenanceLoading) {
            return const SizedBox.shrink();
          } else if (state is MaintenanceLoaded) {
            if (state.requests.isEmpty) {
              return const Center(
                child: Text('No maintenance requests found.'),
              );
            }
            return ListView.builder(
              itemCount: state.requests.length,
              itemBuilder: (context, index) {
                final request = state.requests[index];
                return ListTile(title: Text(request.title));
              },
            );
          } else if (state is MaintenanceError) {
            return Center(child: Text(state.message));
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
