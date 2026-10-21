import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/candidate_profile.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/job_card.dart';
import '../widgets/job_detail_modal.dart';
import '../widgets/match_modal.dart';
import '../widgets/status_view.dart';
import 'tabs/chat_view.dart';
import 'tabs/curtidas_tab.dart';
import 'tabs/matches_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/vagas_tab.dart';

class MainScreen extends StatefulWidget {
  final String userRole;
  final VoidCallback onLogout;
  final ApiService? api;

  const MainScreen({
    super.key,
    this.userRole = "candidate",
    required this.onLogout,
    this.api,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _activeTab = "vagas";
  List<Job> _jobs = [];
  final List<Job> _likedJobs = [];
  final List<MatchItem> _matches = [];

  ApiService get _api => widget.api ?? ApiService.instance;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _jobsError;
  String? _likesError;
  String? _matchesError;
  String? _modality;
  String? _state;
  double? _minSalary;
  int _jobsRequest = 0;
  Job? _lastSkipped;
  final Set<String> _skippedIds = {};
  final Set<String> _pendingLikes = {};
  final Map<String, String> _chatDrafts = {};
  bool _likesLoading = true;
  bool _matchesLoading = true;
  Job? _selectedJob;
  MatchItem? _activeChatMatch;
  CandidateProfile? _candidateProfile;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // A failed secondary request must not hide the available jobs.
    await Future.wait([
      _refreshJobs(),
      _refreshLikes(),
      _refreshMatches(),
      _loadProfile(),
    ]);
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _api.getMyCandidateProfile();
      if (mounted) setState(() => _candidateProfile = profile);
    } catch (_) {
      // Profile remains independently recoverable from the Profile tab.
    }
  }

  Future<void> _refreshJobs() async {
    final request = ++_jobsRequest;
    setState(() {
      _isLoading = true;
      _jobsError = null;
    });
    try {
      final jobs = await _api.getJobRecommendations(
        modality: _modality,
        state: _state,
        minSalary: _minSalary,
      );
      if (!mounted || request != _jobsRequest) return;
      setState(() {
        _jobs = jobs
            .where(
              (job) =>
                  !_skippedIds.contains(job.id) &&
                  !_likedJobs.any((liked) => liked.id == job.id) &&
                  !_pendingLikes.contains(job.id),
            )
            .toList();
      });
    } catch (_) {
      if (mounted && request == _jobsRequest) {
        setState(() => _jobsError = 'Confira sua conexão e tente novamente.');
      }
    } finally {
      if (mounted && request == _jobsRequest) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _applyJobFilters({
    String? modality,
    String? state,
    double? minSalary,
  }) async {
    setState(() {
      _modality = modality;
      _state = state;
      _minSalary = minSalary;
      _lastSkipped = null;
    });
    await _refreshJobs();
  }

  Future<void> _refreshLikes() async {
    setState(() => _likesLoading = true);
    try {
      final likes = await _api.getMyLikes();
      if (!mounted) return;
      setState(() {
        _likesError = null;
        _likedJobs
          ..clear()
          ..addAll(likes);
        _jobs.removeWhere((job) => likes.any((liked) => liked.id == job.id));
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _likesError = 'Suas curtidas não puderam ser atualizadas.',
        );
      }
    } finally {
      if (mounted) setState(() => _likesLoading = false);
    }
  }

  Future<void> _refreshMatches() async {
    setState(() => _matchesLoading = true);
    try {
      final matches = await _api.getMyMatches();
      if (!mounted) return;
      setState(() {
        _matchesError = null;
        _matches
          ..clear()
          ..addAll(matches);
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _matchesError = 'Seus matches não puderam ser atualizados.',
        );
      }
    } finally {
      if (mounted) setState(() => _matchesLoading = false);
    }
  }

  void _undoSkip() {
    final job = _lastSkipped;
    if (job == null) return;
    setState(() {
      _skippedIds.remove(job.id);
      _jobsError = null;
      if (!_jobs.any((item) => item.id == job.id)) _jobs.insert(0, job);
      _lastSkipped = null;
    });
  }

  Future<void> _handleSwipe(Job job, SwipeDirection direction) async {
    if (_isSubmitting || _pendingLikes.contains(job.id)) return;
    if (direction == SwipeDirection.left) {
      setState(() {
        _jobs.removeWhere((item) => item.id == job.id);
        _skippedIds.add(job.id);
        _lastSkipped = job;
      });
      return;
    }
    if (_likedJobs.any((liked) => liked.id == job.id)) {
      _notify('Você já demonstrou interesse nesta vaga.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _pendingLikes.add(job.id);
      // Remove immediately to preserve the swipe transition, but only confirm after success.
      _jobs.removeWhere((item) => item.id == job.id);
    });
    try {
      final result = await _api.likeJob(job.id);
      if (!mounted) return;
      setState(() {
        if (!_likedJobs.any((item) => item.id == job.id)) {
          _likedJobs.insert(0, job);
        }
      });
      if (result.isMatch) {
        // Never invent a conversation id. Refresh if the response omits it.
        if (result.matchId != null) {
          final match = MatchItem(
            id: result.matchId!,
            jobId: job.id,
            company: job.company,
            title: job.title,
            logo: job.logo,
            date: 'Match realizado agora',
          );
          setState(() {
            _matches.removeWhere((item) => item.id == match.id);
            _matches.insert(0, match);
          });
        } else {
          await _refreshMatches();
        }
        if (!mounted) return;
        showMatchModal(
          context: context,
          job: job,
          candidatePhoto: _candidateProfile?.photoUrl,
          candidateName: _candidateProfile?.name,
          onChatNow: () => _openChatWithJob(job),
        );
      } else {
        _notify('Interesse registrado. A vaga está em Curtidas.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (!_jobs.any((item) => item.id == job.id)) _jobs.insert(0, job);
      });
      _notify(
        'Não foi possível confirmar seu interesse. A vaga voltou para a lista.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _pendingLikes.remove(job.id);
        });
      }
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openChatWithJob(Job job) {
    final matching = _matches.where((match) => match.jobId == job.id);
    if (matching.isEmpty) {
      _notify(
        'Seu match foi confirmado. Atualize Matches para abrir a conversa.',
      );
      setState(() => _activeTab = 'matches');
      return;
    }
    final match = matching.first;
    setState(() {
      _activeChatMatch = match;
      _activeTab = "chat";
    });
  }

  void _openChatWithMatch(MatchItem match) {
    setState(() {
      _activeChatMatch = match;
      _activeTab = "chat";
    });
  }

  @override
  Widget build(BuildContext context) {
    final isChatActive = _activeTab == "chat";

    return PopScope(
      canPop: _selectedJob == null && !isChatActive,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          if (_selectedJob != null) {
            _selectedJob = null;
          } else {
            _activeTab = 'matches';
          }
        });
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Content Area
            Positioned.fill(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _buildCurrentContent(),
                ),
              ),
            ),

            // Detail Modal (Slide Up Fullscreen)
            if (_selectedJob != null)
              Positioned.fill(
                child: JobDetailModal(
                  job: _selectedJob!,
                  onClose: () => setState(() => _selectedJob = null),
                  onMatch: (job) {
                    _handleSwipe(job, SwipeDirection.right);
                  },
                ),
              ),
          ],
        ),
        bottomNavigationBar: isChatActive
            ? null
            : _buildCustomBottomNavigationBar(),
      ),
    );
  }

  Widget _buildCurrentContent() {
    switch (_activeTab) {
      case "vagas":
        return VagasTab(
          jobs: _jobs,
          isLoading: _isLoading,
          isSubmitting: _isSubmitting,
          error: _jobsError,
          activeModality: _modality,
          activeState: _state,
          activeMinSalary: _minSalary,
          onUndo: _lastSkipped == null ? null : _undoSkip,
          onSwipe: _handleSwipe,
          onCardClick: (job) => setState(() => _selectedJob = job),
          onResetJobs: _refreshJobs,
          onApplyFilters: _applyJobFilters,
        );
      case "curtidas":
        if (_likesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_likesError != null && _likedJobs.isEmpty) {
          return StatusView(
            title: 'Não foi possível carregar suas curtidas',
            message: _likesError!,
            actionLabel: 'Tentar novamente',
            onAction: _refreshLikes,
            icon: LucideIcons.heart,
          );
        }
        return CurtidasTab(
          likedJobs: _likedJobs,
          errorMessage: _likesError,
          onExplore: () => setState(() => _activeTab = 'vagas'),
          onJobClick: (job) => setState(() => _selectedJob = job),
          onRefresh: _refreshLikes,
        );
      case "matches":
        if (_matchesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_matchesError != null && _matches.isEmpty) {
          return StatusView(
            title: 'Não foi possível carregar seus matches',
            message: _matchesError!,
            actionLabel: 'Tentar novamente',
            onAction: _refreshMatches,
            icon: LucideIcons.messageCircle,
          );
        }
        return MatchesTab(
          matches: _matches,
          errorMessage: _matchesError,
          onExplore: () => setState(() => _activeTab = 'vagas'),
          onSelectMatch: _openChatWithMatch,
          onRefresh: _refreshMatches,
        );
      case "chat":
        if (_activeChatMatch == null) return const SizedBox.shrink();
        return ChatView(
          key: ValueKey(_activeChatMatch!.id),
          api: widget.api,
          initialDraft: _chatDrafts[_activeChatMatch!.id] ?? '',
          onDraftChanged: (text) => _chatDrafts[_activeChatMatch!.id] = text,
          match: _activeChatMatch!,
          onBack: () => setState(() => _activeTab = "matches"),
        );
      case "perfil":
        return ProfileTab(onLogout: widget.onLogout, api: widget.api);
      default:
        return Container();
    }
  }

  Widget _buildCustomBottomNavigationBar() {
    const destinations = [
      NavigationDestination(icon: Icon(LucideIcons.briefcase), label: 'Vagas'),
      NavigationDestination(icon: Icon(LucideIcons.heart), label: 'Curtidas'),
      NavigationDestination(
        icon: Icon(LucideIcons.messageCircle),
        label: 'Matches',
      ),
      NavigationDestination(icon: Icon(LucideIcons.user), label: 'Perfil'),
    ];
    const tabs = ['vagas', 'curtidas', 'matches', 'perfil'];
    return Material(
      color: AppColors.surface,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: NavigationBar(
            selectedIndex: tabs.indexOf(_activeTab).clamp(0, tabs.length - 1),
            onDestinationSelected: (index) => setState(() {
              _selectedJob = null;
              _activeTab = tabs[index];
            }),
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}
