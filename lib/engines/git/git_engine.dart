import 'dart:io';

/// Result of any git operation.
class GitResult {
  final bool success;
  final String output;
  final String error;

  const GitResult({
    required this.success,
    required this.output,
    this.error = '',
  });
}

/// Represents a file changed in the working tree.
class GitFile {
  final String status; // 'M', 'A', 'D', '?', 'R', etc.
  final String path;

  const GitFile({required this.status, required this.path});

  String get statusLabel {
    switch (status.trim()) {
      case 'M':  return 'Modified';
      case 'A':  return 'Added';
      case 'D':  return 'Deleted';
      case '?':  return 'Untracked';
      case 'R':  return 'Renamed';
      case 'C':  return 'Copied';
      case 'U':  return 'Unmerged';
      default:   return status;
    }
  }

  /// Color hint for UI — returned as a simple string token.
  String get statusColor {
    switch (status.trim()) {
      case 'M':  return 'orange';
      case 'A':  return 'green';
      case 'D':  return 'red';
      case 'R':  return 'blue';
      case 'U':  return 'purple';
      default:   return 'grey';
    }
  }
}

class GitEngine {
  final String workingDir;

  GitEngine(this.workingDir);

  // ─── Internal runner ────────────────────────────────────────────────────────

  Future<GitResult> _run(List<String> args, {String? cwd}) async {
    try {
      final result = await Process.run(
        'git',
        args,
        workingDirectory: cwd ?? workingDir,
        environment: {
          ...Platform.environment,
          // Prevent git from opening an editor or asking for credentials.
          'GIT_TERMINAL_PROMPT': '0',
          'GIT_EDITOR': 'true',
        },
      );
      return GitResult(
        success: result.exitCode == 0,
        output: result.stdout.toString().trim(),
        error:  result.stderr.toString().trim(),
      );
    } catch (e) {
      return GitResult(success: false, output: '', error: e.toString());
    }
  }

  // ─── Repo detection ─────────────────────────────────────────────────────────

  Future<bool> isGitRepo() async {
    final result = await _run(['rev-parse', '--is-inside-work-tree']);
    return result.success;
  }

  Future<String?> getRepoRoot() async {
    final result = await _run(['rev-parse', '--show-toplevel']);
    return result.success ? result.output : null;
  }

  // ─── Status ─────────────────────────────────────────────────────────────────

  Future<List<GitFile>> status() async {
    final result = await _run(['status', '--porcelain', '-uall']);
    if (!result.success || result.output.isEmpty) return [];

    return result.output
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          final statusCode = line.substring(0, 2).trim().isNotEmpty
              ? line.substring(0, 2).trim()
              : '?';
          final path = line.length > 3 ? line.substring(3).trim() : line.trim();
          return GitFile(status: statusCode, path: path);
        })
        .toList();
  }

  Future<String> currentBranch() async {
    final result = await _run(['rev-parse', '--abbrev-ref', 'HEAD']);
    return result.success ? result.output : 'unknown';
  }

  Future<String> remoteUrl() async {
    final result = await _run(['remote', 'get-url', 'origin']);
    return result.success ? result.output : 'No remote';
  }

  Future<String> log({int count = 10}) async {
    final result = await _run([
      'log',
      '--oneline',
      '--decorate',
      '-$count',
    ]);
    return result.success ? result.output : '';
  }

  // ─── Branch management ──────────────────────────────────────────────────────

  /// Returns a list of all local branch names.
  Future<List<String>> listBranches() async {
    final result = await _run(['branch', '--format=%(refname:short)']);
    if (!result.success || result.output.isEmpty) return [];
    return result.output
        .split('\n')
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();
  }

  /// Creates and switches to a new branch.
  Future<GitResult> createBranch(String name) =>
      _run(['checkout', '-b', name]);

  /// Switches to an existing branch.
  Future<GitResult> switchBranch(String name) =>
      _run(['checkout', name]);

  /// Deletes a local branch. Use [force] to force-delete (`-D`).
  Future<GitResult> deleteBranch(String name, {bool force = false}) =>
      _run(['branch', force ? '-D' : '-d', name]);

  // ─── Diff ───────────────────────────────────────────────────────────────────

  /// Returns the unified diff for uncommitted changes.
  /// If [filePath] is provided, limits diff to that file.
  Future<String> diff({String? filePath}) async {
    final args = ['diff', 'HEAD'];
    if (filePath != null) args.add(filePath);
    final result = await _run(args);
    return result.output;
  }

  /// Returns the diff for staged (cached) changes.
  Future<String> diffStaged({String? filePath}) async {
    final args = ['diff', '--cached'];
    if (filePath != null) args.add(filePath);
    final result = await _run(args);
    return result.output;
  }

  // ─── Staging ─────────────────────────────────────────────────────────────────

  Future<GitResult> addAll()                            => _run(['add', '.']);
  Future<GitResult> addFile(String path)                => _run(['add', path]);
  Future<GitResult> addFiles(List<String> paths)        => _run(['add', ...paths]);
  Future<GitResult> resetFile(String path)              => _run(['restore', '--staged', path]);
  Future<GitResult> discardFile(String path)            => _run(['checkout', '--', path]);

  // ─── Stash ───────────────────────────────────────────────────────────────────

  Future<GitResult> stash({String? message}) {
    final args = ['stash', 'push'];
    if (message != null) args.addAll(['-m', message]);
    return _run(args);
  }

  Future<GitResult> stashPop()  => _run(['stash', 'pop']);
  Future<GitResult> stashList() => _run(['stash', 'list']);

  // ─── Commit ──────────────────────────────────────────────────────────────────

  Future<GitResult> commit(String message) =>
      _run(['commit', '-m', message]);

  Future<GitResult> amendCommit(String message) =>
      _run(['commit', '--amend', '-m', message]);

  // ─── Remote ops ──────────────────────────────────────────────────────────────

  Future<GitResult> push({String remote = 'origin', String? branch, bool setUpstream = false}) async {
    final b = branch ?? await currentBranch();
    final args = ['push'];
    if (setUpstream) args.addAll(['-u']);
    args.addAll([remote, b]);
    return _run(args);
  }

  Future<GitResult> pull({String remote = 'origin', String? branch}) async {
    final b = branch ?? await currentBranch();
    return _run(['pull', remote, b]);
  }

  Future<GitResult> fetchAll() => _run(['fetch', '--all', '--prune']);

  // ─── Init & clone ────────────────────────────────────────────────────────────

  Future<GitResult> init({String? initialBranch = 'main'}) =>
      _run(['init', '--initial-branch=$initialBranch']);

  Future<GitResult> addRemote(String url, {String name = 'origin'}) =>
      _run(['remote', 'add', name, url]);

  Future<GitResult> setRemoteUrl(String url, {String name = 'origin'}) =>
      _run(['remote', 'set-url', name, url]);

  /// Clones a repository into `destinationPath`. Static — no working dir needed.
  static Future<GitResult> clone(String url, String destinationPath) async {
    try {
      final result = await Process.run(
        'git',
        ['clone', url, destinationPath],
        environment: {
          ...Platform.environment,
          'GIT_TERMINAL_PROMPT': '0',
        },
      );
      return GitResult(
        success: result.exitCode == 0,
        output: result.stdout.toString().trim(),
        error:  result.stderr.toString().trim(),
      );
    } catch (e) {
      return GitResult(success: false, output: '', error: e.toString());
    }
  }

  // ─── Auth helpers ────────────────────────────────────────────────────────────

  /// Embeds the GitHub token into the remote URL so push/pull works over HTTPS
  /// without a password prompt. Format: https://<token>@github.com/owner/repo.git
  Future<GitResult> setRemoteWithToken(String owner, String repo, String token) {
    final url = 'https://$token@github.com/$owner/$repo.git';
    return setRemoteUrl(url);
  }

  Future<GitResult> configUser(String name, String email) async {
    await _run(['config', 'user.name', name]);
    return _run(['config', 'user.email', email]);
  }
}
