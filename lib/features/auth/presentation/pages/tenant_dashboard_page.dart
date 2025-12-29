// ============================================================================
// FILE: lib/features/auth/presentation/pages/tenant_dashboard_page.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class TenantDashboardPage extends StatelessWidget {
  const TenantDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            child: Icon(Icons.person, size: 40),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.user.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '@${state.user.username}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: const Text('Tenant'),
                            backgroundColor: Colors.green.shade100,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tenant Features',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    icon: Icons.home,
                    title: 'My Property',
                    subtitle: 'View your rental property details',
                    onTap: () {},
                  ),
                  _FeatureCard(
                    icon: Icons.payment,
                    title: 'Pay Rent',
                    subtitle: 'Make monthly rental payments',
                    onTap: () {},
                  ),
                  _FeatureCard(
                    icon: Icons.build,
                    title: 'Maintenance Requests',
                    subtitle: 'Submit and track maintenance issues',
                    onTap: () {},
                  ),
                  _FeatureCard(
                    icon: Icons.history,
                    title: 'Payment History',
                    subtitle: 'View your payment records',
                    onTap: () {},
                  ),
                  _FeatureCard(
                    icon: Icons.description,
                    title: 'Lease Agreement',
                    subtitle: 'View your lease documents',
                    onTap: () {},
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
