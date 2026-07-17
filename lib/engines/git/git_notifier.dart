import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import 'git_engine.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum GitOperation { idle, staging, committing, pushing, pulling, cloning, fetching, branching }

// ─── State ───────────────────────────────────────────────────────────────────

class GitState {
  final bool isGitRepo;
  final String currentBranch;
  final List<String> branches;
  final String remoteUrl;
  final String recentLog;
  final List<GitFile> changedFiles;
  final GitOperation operation;
  final String operationOutput;
  final bool hasError;
  final String diffOutput;

  const GitState({
    this.isGitRepo       = false,
    this.currentBranch   = '',
    this.branches        = const [],
    this.remoteUrl       = '',
    this.recentLog       = '',
    this.changedFiles    = const [],
    this.operation       = GitOperation.idle,
    this.operationOutput = '',
    this.hasError        = false,
    this.diffOutput      = '',
  });

  GitState copyWith({
    bool?           isGitRepo,
    String?         currentBranch,
    List<String>?   branches,
    String?         remoteUrl,
    String?         recentLog,
    List<GitFile>?  changedFiles,
    GitOperation?   operation,
    String?         operationOutput,
    bool?           hasError,
    String?         diffOutput,
  }) {
    return GitState(
      isGitRepo:       isGitRepo       ?? this.isGitRepo,
      currentBranch:   currentBranch   ?? this.currentBranch,
      branches:        branches        ?? this.branches,
      remoteUrl:       remoteUrl       ?? this.remoteUrl,
      recentLog:       recentLog       ?? this.recentLog,
      changedFiles:    changedFiles    ?? this.changedFiles,
      operation:       operation       ?? this.operation,
      operationOutput: operationOutput ?? this.operationOutput,
      hasError:        hasError        ?? this.hasError,
      diffOutput:      diffOutput      ?? this.diffOutput,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class GitNotifier extends Notifier<GitState> {
  GitEngine? _engine;

  AppLogger get _logger => ref.read(appLoggerProvider.notifier);

  @override
  GitState build() => const GitState();

  // ─── Project loading ──────────────────────────────────────────────────────

  Future<void> loadProject(String dirPath) async {
    _engine = GitEngine(dirPath);

    final isRepo = await _engine!.isGitRepo();
    if (!isRepo) {
      state = const GitState(isGitRepo: false);
      _logger.info('No git repository found at $dirPath');
      return;
    }

    _logger.info('Git repository detected at $dirPath');
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_engine == null) return;

    final branch   = await _engine!.currentBranch();
    final remote   = await _engine!.remoteUrl();
    final files    = await _engine!.status();
    final log      = await _engine!.log();
    final branches = await _engine!.listBranches();

    state = state.copyWith(
      isGitRepo:       true,
      currentBranch:   branch,
      branches:        branches,
      remoteUrl:       remote,
      changedFiles:    files,
      recentLog:       log,
      operation:       GitOperation.idle,
    );
  }

  // ─── Repo init ────────────────────────────────────────────────────────────

  Future<void> initRepo(String dirPath) async {
    _engine = GitEngine(dirPath);
    final result = await _engine!.init();
    state = state.copyWith(
      isGitRepo:       result.success,
      operationOutput: result.success ? 'Initialized repo at $dirPath' : result.error,
      hasError:        !result.success,
    );
    if (result.success) {
      _logger.success('Initialized git repository at $dirPath');
      await _refresh();
    } else {
      _logger.error('Failed to init repo: ${result.error}');
    }
  }

  // ─── Remote setup ─────────────────────────────────────────────────────────

  Future<void> setRemoteWithToken(String owner, String repo, String token) async {
    if (_engine == null) return;
    final result = await _engine!.setRemoteWithToken(owner, repo, token);
    if (!result.success) {
      // Remote may not exist yet — try adding it instead.
      await _engine!.addRemote('https://$token@github.com/$owner/$repo.git');
    }
    _logger.success('Remote linked → $owner/$repo');
    await _refresh();
  }

  // ─── Staging ──────────────────────────────────────────────────────────────

  Future<void> stageAll() async {
    if (_engine == null) return;
    state = state.copyWith(operation: GitOperation.staging);
    await _engine!.addAll();
    _logger.info('Staged all changes');
    await _refresh();
  }

  Future<void> stageFiles(List<String> files) async {
    if (_engine == null || files.isEmpty) return;
    state = state.copyWith(operation: GitOperation.staging);
    await _engine!.addFiles(files);
    _logger.info('Staged ${files.length} file(s)');
    await _refresh();
  }

  Future<void> unstageFile(String filePath) async {
    if (_engine == null) return;
    await _engine!.resetFile(filePath);
    _logger.info('Unstaged: $filePath');
    await _refresh();
  }

  Future<void> discardFile(String filePath) async {
    if (_engine == null) return;
    await _engine!.discardFile(filePath);
    _logger.warning('Discarded changes in: $filePath');
    await _refresh();
  }

  // ─── Commit ───────────────────────────────────────────────────────────────

  Future<void> commit(String message) async {
    if (_engine == null) return;
    state = state.copyWith(operation: GitOperation.committing);
    final result = await _engine!.commit(message);
    state = state.copyWith(
      operationOutput: result.success ? 'Committed: $message' : result.error,
      hasError:        !result.success,
    );
    if (result.success) {
      _logger.success('Committed: "$message"');
    } else {
      _logger.error('Commit failed: ${result.error}');
    }
    await _refresh();
  }

  // ─── Push / Pull ──────────────────────────────────────────────────────────

  Future<void> push({bool setUpstream = false}) async {
    if (_engine == null) return;
    state = state.copyWith(operation: GitOperation.pushing);
    _logger.info('Pushing to ${state.remoteUrl}...');
    final result = await _engine!.push(setUpstream: setUpstream);
    state = state.copyWith(
      operationOutput: result.success ? 'Pushed successfully!' : result.error,
      hasError:        !result.success,
      operation:       GitOperation.idle,
    );
    if (result.success) {
      _logger.success('Push successful');
    } else {
      _logger.error('Push failed: ${result.error}');
    }
    await _refresh();
  }

  Future<void> pull() async {
    if (_engine == null) return;
    state = state.copyWith(operation: GitOperation.pulling);
    _logger.info('Pulling from remote...');
    final result = await _engine!.pull();
    final output = result.success
        ? (result.output.isNotEmpty ? result.output : 'Already up to date.')
        : result.error;
    state = state.copyWith(
      operationOutput: output,
      hasError:        !result.success,
      operation:       GitOperation.idle,
    );
    if (result.success) {
      _logger.success('Pull complete: $output');
    } else {
      _logger.error('Pull failed: ${result.error}');
    }
    await _refresh();
  }

  Future<void> fetchAll() async {
    if (_engine == null) return;
    state = state.copyWith(operation: GitOperation.fetching);
    _logger.info('Fetching all remotes...');
    final result = await _engine!.fetchAll();
    state = state.copyWith(
      operationOutput: result.success ? 'Fetched all remotes.' : result.error,
      hasError:        !result.success,
      operation:       GitOperation.idle,
    );
    if (result.success) {
      _logger.success('Fetch complete');
    } else {
      _logger.error('Fetch failed: ${result.error}');
    }
    await _refresh();
  }

  // ─── Branch management ────────────────────────────────────────────────────

  Future<void> createBranch(String name) async {
    if (_engine == null) return;
    state = state.copyWith(operation: GitOperation.branching);
    final result = await _engine!.createBranch(name);
    state = state.copyWith(
      operationOutput: result.success ? 'Created and switched to branch: $name' : result.error,
      hasError:        !result.success,
    );
    if (result.success) {
      _logger.success('Created branch: $name');
    } else {
      _logger.error('Branch creation failed: ${result.error}');
    }
    await _refresh();
  }

  Future<void> switchBranch(String name) async {
    if (_engine == null) return;
    state = state.copyWith(operation: GitOperation.branching);
    final result = await _engine!.switchBranch(name);
    state = state.copyWith(
      operationOutput: result.success ? 'Switched to branch: $name' : result.error,
      hasError:        !result.success,
    );
    if (result.success) {
      _logger.success('Switched to: $name');
    } else {
      _logger.error('Branch switch failed: ${result.error}');
    }
    await _refresh();
  }

  Future<void> deleteBranch(String name, {bool force = false}) async {
    if (_engine == null) return;
    final result = await _engine!.deleteBranch(name, force: force);
    state = state.copyWith(
      operationOutput: result.success ? 'Deleted branch: $name' : result.error,
      hasError:        !result.success,
    );
    if (result.success) {
      _logger.warning('Deleted branch: $name');
    } else {
      _logger.error('Delete failed: ${result.error}');
    }
    await _refresh();
  }

  // ─── Stash ────────────────────────────────────────────────────────────────

  Future<void> stash({String? message}) async {
    if (_engine == null) return;
    final result = await _engine!.stash(message: message);
    state = state.copyWith(
      operationOutput: result.success ? 'Changes stashed.' : result.error,
      hasError:        !result.success,
    );
    if (result.success) {
      _logger.info('Stashed changes${message != null ? ': $message' : ''}');
    } else {
      _logger.error('Stash failed: ${result.error}');
    }
    await _refresh();
  }

  Future<void> stashPop() async {
    if (_engine == null) return;
    final result = await _engine!.stashPop();
    state = state.copyWith(
      operationOutput: result.success ? 'Stash restored.' : result.error,
      hasError:        !result.success,
    );
    if (result.success) {
      _logger.success('Stash popped');
    } else {
      _logger.error('Stash pop failed: ${result.error}');
    }
    await _refresh();
  }

  // ─── Diff ─────────────────────────────────────────────────────────────────

  Future<void> loadDiff({String? filePath}) async {
    if (_engine == null) return;
    final diff = await _engine!.diff(filePath: filePath);
    state = state.copyWith(diffOutput: diff);
  }

  void clearDiff() => state = state.copyWith(diffOutput: '');

  // ─── Clone (static) ───────────────────────────────────────────────────────

  static Future<GitResult> clone(String url, String destPath) =>
      GitEngine.clone(url, destPath);
}

// ─── Provider ────────────────────────────────────────────────────────────────

final gitProvider =
    NotifierProvider<GitNotifier, GitState>(() => GitNotifier());
