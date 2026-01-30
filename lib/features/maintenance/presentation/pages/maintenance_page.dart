import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_again/core/widgets/gradient_floating_action_button.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import 'package:login_again/core/widgets/app_loading_indicator.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/maintenance_repository.dart';
import '../widgets/request_card.dart';
import '../widgets/filter_chip.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  late MaintenanceRepository _repo;
  late Future<List<MaintenanceRequestItem>> _future;
  bool _isCreating = false;
  String _filter = 'all'; // all | open | in_progress | done
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _newCategory = '';
  List<XFile> _photos = [];

  @override
  void initState() {
    super.initState();
    final authCubit = context.read<AuthCubit>();
    _repo = MaintenanceRepository(
      apiClient: authCubit.apiClient,
      authCubit: authCubit,
    );
    _future = _repo.listMyRequests();
  }

  Widget _categoryIcon(String category) {
    final scheme = Theme.of(context).colorScheme;
    final config = <String, Map<String, dynamic>>{
      'plumbing': {
        'icon': Icons.build,
        'bg': Colors.blueAccent.withValues(alpha: 0.12),
        'fg': Colors.blue,
      },
      'electrical': {
        'icon': Icons.bolt,
        'bg': Colors.amber.withValues(alpha: 0.12),
        'fg': Colors.amber,
      },
      'hvac': {
        'icon': Icons.thermostat,
        'bg': Colors.cyan.withValues(alpha: 0.12),
        'fg': Colors.cyan,
      },
      'appliance': {
        'icon': Icons.settings,
        'bg': Colors.purple.withValues(alpha: 0.12),
        'fg': Colors.purple,
      },
      'other': {
        'icon': Icons.build,
        'bg': scheme.surface,
        'fg': scheme.onSurface.withValues(alpha: 0.7),
      },
    };
    final c = config[category] ?? config['other']!;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c['bg'] as Color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(c['icon'] as IconData, color: c['fg'] as Color, size: 20),
    );
  }

  Widget _buildCreateOverlay(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_isCreating,
        child: AnimatedOpacity(
          opacity: _isCreating ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'New Request',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(() => _isCreating = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Category',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 3.2,
                              ),
                          children: [
                            _categoryChip('plumbing', 'Plumbing'),
                            _categoryChip('electrical', 'Electrical'),
                            _categoryChip('hvac', 'HVAC'),
                            _categoryChip('appliance', 'Appliance'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "What's the issue?",
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _titleCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g., Leaky faucet in bathroom',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Description',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _descCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                'Provide more details about the problem...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: scheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: scheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Add Photos (optional)',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GradientOutlinedButton(
                          onPressed: _handleAddPhotos,
                          minHeight: 48,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.photo_camera_outlined),
                              SizedBox(width: 8),
                              Text('Tap to add photos'),
                            ],
                          ),
                        ),
                        if (_photos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${_photos.length} photo(s) selected',
                              style: textTheme.labelMedium,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: GradientButton(
                            onPressed: _submit,
                            minHeight: 48,
                            borderRadius: BorderRadius.circular(24),
                            child: const Text('Submit Request'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String id, String label) {
    final isActive = _newCategory == id;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => setState(() => _newCategory = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? scheme.primary : scheme.outline,
            width: 2,
          ),
          color: isActive ? scheme.primary.withValues(alpha: 0.08) : null,
        ),
        child: Row(
          children: [
            _categoryIcon(id),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repo.listMyRequests();
    });
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a title for the request.'),
        ),
      );
      return;
    }
    try {
      final taskId = await _repo.createRequest(name: title);
      for (final x in _photos) {
        try {
          final bytes = await x.readAsBytes();
          await _repo.attachImage(
            taskId: taskId,
            bytes: bytes,
            filename: x.name,
          );
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maintenance request submitted (ID: $taskId).')),
      );
      setState(() {
        _isCreating = false;
        _titleCtrl.clear();
        _descCtrl.clear();
        _newCategory = '';
        _photos = [];
        _future = _repo.listMyRequests();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit request: $e')));
    }
  }

  Future<void> _handleAddPhotos() async {
    final picker = ImagePicker();
    try {
      final files = await picker.pickMultiImage(imageQuality: 85);
      if (!mounted) return;
      if (files.isNotEmpty) {
        setState(() {
          _photos = files;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to pick photos: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<MaintenanceRequestItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load requests\n${snapshot.error}'),
            );
          }
          final allItems = snapshot.data ?? const <MaintenanceRequestItem>[];
          final items = allItems
              .where((r) => _filter == 'all' || r.state == _filter)
              .toList();
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track and submit repair requests',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          MaintenanceFilterChip(
                            id: 'all',
                            label: 'All',
                            isActive: _filter == 'all',
                            onSelected: (_) => setState(() => _filter = 'all'),
                          ),
                          const SizedBox(width: 8),
                          MaintenanceFilterChip(
                            id: 'open',
                            label: 'Open',
                            isActive: _filter == 'open',
                            onSelected: (_) => setState(() => _filter = 'open'),
                          ),
                          const SizedBox(width: 8),
                          MaintenanceFilterChip(
                            id: 'in_progress',
                            label: 'In Progress',
                            isActive: _filter == 'in_progress',
                            onSelected: (_) =>
                                setState(() => _filter = 'in_progress'),
                          ),
                          const SizedBox(width: 8),
                          MaintenanceFilterChip(
                            id: 'done',
                            label: 'Completed',
                            isActive: _filter == 'done',
                            onSelected: (_) => setState(() => _filter = 'done'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.build_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No requests',
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refresh,
                              child: ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) =>
                                    MaintenanceRequestCard(
                                      item: items[index],
                                      index: index,
                                    ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              _buildCreateOverlay(context),
            ],
          );
        },
      ),
      floatingActionButton: _isCreating
          ? null
          : GradientFloatingActionButton(
              onPressed: () => setState(() => _isCreating = true),
              child: const Icon(Icons.add),
            ),
    );
  }
}
