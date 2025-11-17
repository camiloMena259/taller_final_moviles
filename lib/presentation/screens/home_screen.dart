import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/task_providers.dart';
import '../widgets/task_list_item.dart';
import '../widgets/sync_status_indicator.dart';
import 'task_form_screen.dart';

/// Pantalla principal que muestra la lista de tareas
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksWithRefreshProvider);
    final currentFilter = ref.watch(taskFilterProvider);
    final syncNow = ref.read(syncNowProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Indicador de estado de sincronización
          const SyncStatusIndicator(),
          
          // Botón de sincronización manual
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              try {
                await syncNow();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sincronización completada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al sincronizar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            tooltip: 'Sincronizar ahora',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _FilterChips(currentFilter: currentFilter),
        ),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return _EmptyState(filter: currentFilter);
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.read(refreshTasksProvider.notifier).state++;
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              itemCount: tasks.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                return TaskListItem(task: tasks[index]);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar tareas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(refreshTasksProvider.notifier).state++;
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TaskFormScreen(),
            ),
          );
        },
        tooltip: 'Agregar tarea',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Widget de chips de filtro
class _FilterChips extends ConsumerWidget {
  final TaskFilter currentFilter;

  const _FilterChips({required this.currentFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: TaskFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.displayName),
              selected: currentFilter == filter,
              onSelected: (selected) {
                if (selected) {
                  ref.read(taskFilterProvider.notifier).state = filter;
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget de estado vacío
class _EmptyState extends StatelessWidget {
  final TaskFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;

    switch (filter) {
      case TaskFilter.all:
        message = 'No tienes tareas aún.\n¡Crea tu primera tarea!';
        icon = Icons.inbox_outlined;
        break;
      case TaskFilter.pending:
        message = '¡Genial! No tienes tareas pendientes.';
        icon = Icons.check_circle_outline;
        break;
      case TaskFilter.completed:
        message = 'No has completado ninguna tarea aún.';
        icon = Icons.assignment_outlined;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}
