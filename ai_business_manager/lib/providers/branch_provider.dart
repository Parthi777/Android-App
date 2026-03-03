import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/branch.dart';
import '../core/app_cache.dart';

// Notifier to manage the current active Branch
class BranchNotifier extends Notifier<Branch?> {
  @override
  Branch? build() {
    final cache = ref.read(appCacheProvider).value;
    if (cache != null) {
      final cachedBranchData = cache.readJson('active_branch');
      if (cachedBranchData != null) {
        return Branch.fromJson(cachedBranchData);
      }
    }
    return null;
  }

  Future<void> setActiveBranch(Branch branch) async {
    state = branch;
    final cache = ref.read(appCacheProvider).value;
    await cache?.writeJson('active_branch', branch.toJson());
  }

  void clearActiveBranch() {
    state = null;
    final cache = ref.read(appCacheProvider).value;
    cache?.remove('active_branch');
  }
}

// Global Provider for the active branch
final branchProvider = NotifierProvider<BranchNotifier, Branch?>(() {
  return BranchNotifier();
});

// Notifier to manage the list of saved branches
class BranchesListNotifier extends Notifier<List<Branch>> {
  @override
  List<Branch> build() {
    final cache = ref.read(appCacheProvider).value;
    if (cache != null) {
      final cachedList = cache.readJsonList('saved_branches');
      if (cachedList != null) {
        return cachedList.map((json) => Branch.fromJson(json)).toList();
      }
    }
    return [];
  }

  Future<void> addBranch(Branch branch) async {
    final newList = [...state, branch];
    state = newList;
    final cache = ref.read(appCacheProvider).value;
    await cache?.writeJsonList(
      'saved_branches',
      newList.map((b) => b.toJson()).toList(),
    );

    // Auto-set as active if it's the first branch
    if (newList.length == 1) {
      ref.read(branchProvider.notifier).setActiveBranch(branch);
    }
  }

  Future<void> removeBranch(String id) async {
    final newList = state.where((b) => b.id != id).toList();
    state = newList;
    final cache = ref.read(appCacheProvider).value;
    await cache?.writeJsonList(
      'saved_branches',
      newList.map((b) => b.toJson()).toList(),
    );

    // If active branch is removed, clear it
    final activeBranch = ref.read(branchProvider);
    if (activeBranch?.id == id) {
      ref.read(branchProvider.notifier).clearActiveBranch();
    }
  }
}

final branchesListProvider =
    NotifierProvider<BranchesListNotifier, List<Branch>>(() {
      return BranchesListNotifier();
    });
