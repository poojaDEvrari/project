import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_service.dart';
import 'projects_service.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _service = ProjectsService(baseUrl: 'http://98.86.182.22');
  late Future<List<Map<String, dynamic>>> _future;

  @override
 void initState() {
  super.initState();
  // TEMP: verify token presence
  AuthService().getToken().then((t) {
    debugPrint('Auth token present? ${t != null && t.isNotEmpty}');
  });
  _future = _service.fetchProjects();
}
  Future<void> _refresh() async {
    // small delay to let the backend finalize writes, then fetch fresh
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _future = _service.fetchProjects());
    await _future;
  }

  void _openCreateDialog() async {
    final createdProject = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CreateProjectDialog(service: _service),
    );
    if (createdProject != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project created successfully')),
      );
      // Optimistically prepend to current list, then refresh from server
      setState(() {
        _future = _future.then((old) {
          final current = List<Map<String, dynamic>>.from(old ?? const []);
          return [createdProject, ...current];
        });
      });
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refresh();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: ${snapshot.error}'),
                  )
                ],
              );
            }
            // Copy and sort so newest appears first
            final items = List<Map<String, dynamic>>.from(snapshot.data ?? []);
            items.sort((a, b) {
              DateTime pa;
              DateTime pb;
              try {
                pa = DateTime.tryParse((a['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
                pb = DateTime.tryParse((b['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
              } catch (_) {
                pa = DateTime.fromMillisecondsSinceEpoch(0);
                pb = DateTime.fromMillisecondsSinceEpoch(0);
              }
              final cmp = pb.compareTo(pa);
              if (cmp != 0) return cmp;
              return (b['project_name'] ?? '').toString().compareTo((a['project_name'] ?? '').toString());
            });
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No projects yet. Tap New Project to create one.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = items[index];
                final title = (p['project_name'] ?? 'Untitled').toString();
                final address = (p['address'] ?? '').toString();
                final scanDate = (p['scan_date'] ?? '').toString();
                return Card(
                  elevation: 1,
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text([address, scanDate].where((e) => e.isNotEmpty).join(' • ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final id = (p['id'] ?? '').toString();
                      final encodedName = Uri.encodeComponent(title);
                      // Navigate to Home with selected project context
                      context.go('/home?project=$id&name=$encodedName');
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CreateProjectDialog extends StatefulWidget {
  final ProjectsService service;
  const _CreateProjectDialog({required this.service});

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(); // YYYY-MM-DD
  final _floorPlanCtrl = TextEditingController();
  final _policyCtrl = TextEditingController();
  final _scopeCtrl = TextEditingController();
  bool _encrypted = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateCtrl.text = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _dateCtrl.dispose();
    _floorPlanCtrl.dispose();
    _policyCtrl.dispose();
    _scopeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final created = await widget.service.createProject(
        projectName: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        scanDate: _dateCtrl.text.trim(),
        floorPlan: _floorPlanCtrl.text.trim().isEmpty ? null : _floorPlanCtrl.text.trim(),
        dataAtRestEncrypted: _encrypted,
        accessPolicyId: _policyCtrl.text.trim().isEmpty ? null : _policyCtrl.text.trim(),
        s3KeyScope: _scopeCtrl.text.trim().isEmpty ? null : _scopeCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create project: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Project'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Project name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _dateCtrl,
                decoration: const InputDecoration(labelText: 'Scan date (YYYY-MM-DD) *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _floorPlanCtrl,
                decoration: const InputDecoration(labelText: 'Floor plan (optional)'),
              ),
              SwitchListTile(
                value: _encrypted,
                onChanged: (v) => setState(() => _encrypted = v),
                title: const Text('Data at rest encrypted'),
              ),
              TextFormField(
                controller: _policyCtrl,
                decoration: const InputDecoration(labelText: 'Access policy id (optional)'),
              ),
              TextFormField(
                controller: _scopeCtrl,
                decoration: const InputDecoration(labelText: 'S3 key scope (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        )
      ],
    );
  }
}
