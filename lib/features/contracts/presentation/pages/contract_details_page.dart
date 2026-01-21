import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/core/utils/file_utils.dart';
import 'package:login_again/core/utils/formatters.dart';
import 'package:login_again/features/contracts/presentation/widgets/widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/contracts_repository.dart';
import 'package:login_again/core/widgets/app_loading_indicator.dart';

class ContractPage extends StatefulWidget {
  const ContractPage({super.key});

  @override
  State<ContractPage> createState() => _ContractPageState();
}

class _ContractPageState extends State<ContractPage> {
  late ContractsRepository _repo;
  late Future<ContractDetails?> _future;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>();
    _repo = ContractsRepository(apiClient: auth.apiClient, authCubit: auth);
    _future = _repo.getCurrentContract();
  }

  Future<void> _downloadAndShare(ContractDetails details) async {
    try {
      final bytes = await _repo.downloadContractPdf(contractId: details.id);
      final path = await savePdfToDocuments(
        bytes,
        'contract_${details.id}.pdf',
      );
      await openFile(path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save or open contract')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: FutureBuilder<ContractDetails?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load contract\n${snapshot.error}'),
              ),
            );
          }
          final details = snapshot.data;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'View and manage your contract agreement',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                if (details == null)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No active contract found')),
                    ),
                  )
                else
                  ContractCard(details: details),

                const SizedBox(height: 24),

                const Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (details != null)
                  ActionTile(
                    icon: Icons.download,
                    title: 'Download Contract',
                    subtitle: 'Get a PDF copy of your signed contract',
                    onTap: () => _downloadAndShare(details),
                  )
                else
                  const ActionTile(
                    icon: Icons.download,
                    title: 'Download Contract',
                    subtitle: 'Get a PDF copy of your signed contract',
                  ),
                const SizedBox(height: 8),

                const SizedBox(height: 24),

                const Text(
                  'Important Dates',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ImportantDatesCard(dateText: formatDate(details?.endDate)),
              ],
            ),
          );
        },
      ),
    );
  }
}
