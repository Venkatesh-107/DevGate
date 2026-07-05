import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'git_engine.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum GitOperation { idle, staging, committing, pushing, pulling, cloning }

class GitState {
  final bool isGitRepo;
  final String currentBranch;
  final String remoteUrl;
  final String recentLog;
  final List<GitFile> changedFiles;
  final GitOperation operation;
  final String operationOutput;
  final bool hasError;

  const GitState({
    this.isGitRepo = false,
    this.currentBranch = '',
    this.remoteUrl = '',
    this.recentLog = '',
    this.changedFiles = const [],
    this.operation = GitOperation.idle,
    this.operationOutput = '',
    this.hasError = false,
  });

  GitState copyWith({
    bool? isGitRepo,
    String? currentBranch,
    String? remoteUrl,
    String? recentLog,
    List<GitFile>? changedFiles,
    GitOperation? operation,
    String? operationOutput,
    bool? hasError,
  }) {
    return GitState(
      isGitRepo: isGitRepo ?? this.isGitRepo,
      currentBranch: currentBranch ?? this.currentBranch,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      recentLog: recentLog ?? this.recentLog,
      changedFiles: changedFiles ?? this.changedFiles,
      operation: operation ?? this.operation,
      operationOutput: operationOutput ?? this.operationOutput,
      hasError: hasError ?? this.hasError,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class GitNotifier extends Notifier<GitState> {
  GitEngine? _engine;

  @override
  GitState build() => const GitState();

  Future<void> loadProject(String dirPath) async {
    _engine = GitEngine(dirPath);

    final isRepo = await _engine!.isGitRepo();
    if (!isRepo) {
      state = const GitState(isGitRepo: false);
      return;
    }

    await _refresh();
  }

  Future<void> _refresh() async {
    if (_engine == null) return;
    final branch = await _engine!.currentBranch();
    final remote = await _engine!.remoteUrl();
    final files = await _engine!.status();
    final log = await _engine!.log();

    state = state.copyWith(
      isGitRepo: true,
      currentBranch: branch,
      remoteUrl: remote,
      changedFiles: files,
      recentLog: log,
      operation: GitOperation.idle,
    );
  }

  Future<void> initRepo(String dirPath) async {
    _engine = GitEngine(dirPath);
    final result = await _engine!.init();
    state = state.copyWith(
      isGitRepo: result.success,
      operationOutput: result.success ? 'Initialized repo at $dirPath' : result.error,
      hasError: !result.success,
    );
    if (result.success) await _refresh();
  }

  Future<void> setRemoteWithToken(String owner, String repo, String token) async {
    if (_engine == null) return;
    final result = await _engine!.setRemoteWithToken(owner, repo, token);
    if (!result.success) {
      // Try adding remote if set-url failed (no remote exists yet)
      await _engine!.addRemote('https://$token@github.com/$owner/$repo.git');
    }
    await _refresh();
  }

  Future<void> stageAll() async {
    if (_engine == null) return;
    state = state.copyWith(operation: GitOperation.staging);
    await _engine!.addAll();
    await _refresh();
  }

  Future<void> stageFiles(List<String> files) async {
    if (_engine == null || files.isEmpty) return;
    state = state.copyWith(operation: GitOperation.staging);
    await _engine!.addFiles(files);
    await _refresh();
  }

  Future<void> commit(String message) async {
    if (_engine == null) return;
    state = state.copyWith(operation: GitOperation.committing);
    final result = await _engine!.commit(message);
    state = state.copyWith(
      operationOutput: result.success ? 'Committed: $message' : result.error,
      hasError: !result.success,
    );
    await _refresh();
  }

  Future<void> push() async {
    if (_engine == null) return;
    state = state.copyWith(operation: GitOperation.pushing);
    final result = await _engine!.push();
    state = state.copyWith(
      operationOutput: result.success ? 'Pushed successfully!' : result.error,
      hasError: !result.success,
      operation: GitOperation.idle,
    );
    await _refresh();
  }

  Future<void> pull() async {
    if (_engine == null) return;
    state = state.copyWith(operation: GitOperation.pulling);
    final result = await _engine!.pull();
    state = state.copyWith(
      operationOutput: result.success ? result.output.isNotEmpty ? result.output : 'Already up to date.' : result.error,
      hasError: !result.success,
      operation: GitOperation.idle,
    );
    await _refresh();
  }

  static Future<GitResult> clone(String url, String destPath) {
    return GitEngine.clone(url, destPath);
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final gitProvider = NotifierProvider<GitNotifier, GitState>(() => GitNotifier());
