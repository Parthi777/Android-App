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
