import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/maintenance_repository.dart';
import 'cubit/maintenance_cubit.dart';
import 'cubit/maintenance_state.dart';
import 'package:login_again/core/api/api_client.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  late final MaintenanceCubit maintenanceCubit;

  @override
  void initState() {
    super.initState();

    // Create the Cubit locally for this screen only
    maintenanceCubit = MaintenanceCubit(
      MaintenanceRepository(apiClient: ApiClient()),
    );
    // Get the partner ID from AuthCubit
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      print('the partner id is: ${authState.user.partnerId}');
      maintenanceCubit.loadRequests(authState.user.partnerId);
    }
  }

  @override
  void dispose() {
    // Close the Cubit when the screen is disposed
    maintenanceCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      // Provide the Cubit to the widget tree for BlocBuilder
      value: maintenanceCubit,
      child: Scaffold(
        appBar: AppBar(title: const Text('Maintenance Requests')),
        body: BlocBuilder<MaintenanceCubit, MaintenanceState>(
          builder: (context, state) {
            if (state is MaintenanceLoading) {
              return const Center(child: CircularProgressIndicator());
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
      ),
    );
  }
}
