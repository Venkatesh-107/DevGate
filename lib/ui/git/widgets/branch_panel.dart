import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../engines/git/git_notifier.dart';

/// Collapsible branch management panel for the Git screen.
///
/// Features:
/// - Current branch badge
/// - Full list of local branches
/// - Create / switch / delete branches
class BranchPanel extends ConsumerStatefulWidget {
  const BranchPanel({super.key});

  @override
  ConsumerState<BranchPanel> createState() => _BranchPanelState();
}

class _BranchPanelState extends ConsumerState<BranchPanel> {
  bool _expanded = false;
  final _newBranchCtrl = TextEditingController();

  @override
  void dispose() {
    _newBranchCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _createBranch() async {
    final name = _newBranchCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Enter a branch name first.');
      return;
    }
    _newBranchCtrl.clear();
    await ref.read(gitProvider.notifier).createBranch(name);
    _snack('Created and switched to "$name"');
  }

  Future<void> _confirmDelete(String branch, String current) async {
    if (branch == current) {
      _snack('Cannot delete the currently checked-out branch.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Branch', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete branch "$branch"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(gitProvider.notifier).deleteBranch(branch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final git = ref.watch(gitProvider);
    final isBusy = git.operation != GitOperation.idle;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3C4043)),
      ),
      child: Column(
        children: [
          // ── Collapse header ─────────────────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.account_tree_outlined,
                      color: Color(0xFF8AB4F8), size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Branch Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Current branch badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      git.currentBranch.isEmpty ? '—' : git.currentBranch,
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded body ────────────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildBody(git, isBusy),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(GitState git, bool isBusy) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF3C4043))),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Create new branch ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newBranchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onSubmitted: (_) => isBusy ? null : _createBranch(),
                  decoration: InputDecoration(
                    hintText: 'new-branch-name',
                    hintStyle: const TextStyle(color: Colors.white24),
                    prefixIcon: const Icon(Icons.add, color: Colors.grey, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF131314),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF3C4043)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF8AB4F8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: isBusy ? null : _createBranch,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8AB4F8),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Fetch button ────────────────────────────────────────────────
          Row(
            children: [
              const Text(
                'Local Branches',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: isBusy
                    ? null
                    : () => ref.read(gitProvider.notifier).fetchAll(),
                icon: const Icon(Icons.sync, size: 14),
                label: const Text('Fetch All', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Branch list ─────────────────────────────────────────────────
          if (git.branches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No local branches found.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                color: const Color(0xFF131314),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: git.branches.length,
                separatorBuilder: (_, a) =>
                    const Divider(height: 1, color: Color(0xFF3C4043)),
                itemBuilder: (_, i) {
                  final branch = git.branches[i];
                  final isCurrent = branch == git.currentBranch;
                  return ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    leading: Icon(
                      isCurrent
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isCurrent
                          ? Colors.greenAccent
                          : Colors.white38,
                      size: 16,
                    ),
                    title: Text(
                      branch,
                      style: TextStyle(
                        color: isCurrent ? Colors.greenAccent : Colors.white70,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    trailing: isCurrent
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('current',
                                style: TextStyle(
                                    color: Colors.greenAccent, fontSize: 10)),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Switch
                              IconButton(
                                iconSize: 16,
                                tooltip: 'Switch to $branch',
                                icon: const Icon(Icons.swap_horiz,
                                    color: Color(0xFF8AB4F8)),
                                onPressed: isBusy
                                    ? null
                                    : () => ref
                                        .read(gitProvider.notifier)
                                        .switchBranch(branch),
                              ),
                              // Delete
                              IconButton(
                                iconSize: 16,
                                tooltip: 'Delete $branch',
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: isBusy
                                    ? null
                                    : () => _confirmDelete(
                                        branch, git.currentBranch),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
