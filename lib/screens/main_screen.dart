import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/mock_data.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/job_card.dart';
import '../widgets/job_detail_modal.dart';
import '../widgets/match_modal.dart';
import 'tabs/chat_view.dart';
import 'tabs/company_jobs_tab.dart';
import 'tabs/curtidas_tab.dart';
import 'tabs/matches_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/vagas_tab.dart';

class MainScreen extends StatefulWidget {
  final String userRole;
  final VoidCallback onLogout;

  const MainScreen({
    super.key,
    this.userRole = "candidate",
    required this.onLogout,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _activeTab = "vagas";
  List<Job> _jobs = [];
  final List<Job> _likedJobs = [];
  final List<MatchItem> _matches = [];

  bool _isLoading = true;
  Job? _selectedJob;
  Job? _showMatchJob;
  MatchItem? _activeChatMatch;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      if (widget.userRole == "candidate") {
        final jobs = await ApiService.instance.getJobRecommendations();
        final likes = await ApiService.instance.getMyLikes();
        final matches = await ApiService.instance.getMyMatches();

        if (mounted) {
          setState(() {
            _jobs = jobs.isNotEmpty ? jobs : List.from(mockJobs);
            _likedJobs.clear();
            _likedJobs.addAll(likes);
            _matches.clear();
            _matches.addAll(matches);
          });
        }
      } else {
        // Company user
        final companyJobs = await ApiService.instance.getMyCompanyJobs();
        final matches = await ApiService.instance.getMyMatches();

        if (mounted) {
          setState(() {
            _jobs = companyJobs.isNotEmpty ? companyJobs : List.from(mockJobs);
            _matches.clear();
            _matches.addAll(matches);
          });
        }
      }
    } catch (_) {
      if (mounted && _jobs.isEmpty) {
        setState(() {
          _jobs = List.from(mockJobs);
          _matches.addAll(mockMatches);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshJobs() async {
    try {
      if (widget.userRole == "candidate") {
        final jobs = await ApiService.instance.getJobRecommendations();
        if (mounted) {
          setState(() {
            _jobs = jobs.isNotEmpty ? jobs : List.from(mockJobs);
          });
        }
      } else {
        final companyJobs = await ApiService.instance.getMyCompanyJobs();
        if (mounted) {
          setState(() {
            _jobs = companyJobs.isNotEmpty ? companyJobs : List.from(mockJobs);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshLikes() async {
    try {
      final likes = await ApiService.instance.getMyLikes();
      if (mounted) {
        setState(() {
          _likedJobs.clear();
          _likedJobs.addAll(likes);
        });
      }
    } catch (_) {}
  }

  Future<void> _refreshMatches() async {
    try {
      final matches = await ApiService.instance.getMyMatches();
      if (mounted) {
        setState(() {
          _matches.clear();
          _matches.addAll(matches);
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSwipe(Job job, SwipeDirection direction) async {
    setState(() {
      _jobs.removeWhere((item) => item.id == job.id);
    });

    if (direction == SwipeDirection.right) {
      if (!_likedJobs.any((j) => j.id == job.id)) {
        setState(() {
          _likedJobs.add(job);
        });
      }

      try {
        final result = await ApiService.instance.likeJob(job.id);
        if (result.isMatch) {
          final matchItem = MatchItem(
            id: result.matchId ?? "m_${DateTime.now().millisecondsSinceEpoch}",
            jobId: job.id,
            company: job.company,
            title: job.title,
            logo: job.logo,
            date: "Match realizado agora!",
          );
          if (mounted) {
            setState(() {
              _matches.removeWhere((m) => m.jobId == job.id);
              _matches.insert(0, matchItem);
              _showMatchJob = job;
            });
          }
        }
      } catch (_) {
        // Continue smoothly even if offline
      }
    }
  }

  void _openChatWithJob(Job job) {
    final match = _matches.firstWhere(
      (m) => m.jobId == job.id,
      orElse: () => MatchItem(
        id: "m_${job.id}",
        jobId: job.id,
        company: job.company,
        title: job.title,
        logo: job.logo,
        date: "Match realizado agora",
      ),
    );
    setState(() {
      _showMatchJob = null;
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Content Area
          Positioned.fill(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCurrentContent(),
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

          // Match Celebration Modal Overlay
          if (_showMatchJob != null)
            Positioned.fill(
              child: MatchModal(
                job: _showMatchJob!,
                onClose: () => setState(() => _showMatchJob = null),
                onChatNow: () => _openChatWithJob(_showMatchJob!),
              ),
            ),
        ],
      ),
      bottomNavigationBar:
          isChatActive ? null : _buildCustomBottomNavigationBar(),
    );
  }

  Widget _buildCurrentContent() {
    switch (_activeTab) {
      case "vagas":
        if (widget.userRole == "candidate") {
          return VagasTab(
            jobs: _jobs,
            onSwipe: _handleSwipe,
            onCardClick: (job) => setState(() => _selectedJob = job),
            onResetJobs: _refreshJobs,
          );
        } else {
          return CompanyJobsTab(
            jobs: _jobs,
            onRefresh: _refreshJobs,
            onJobClick: (job) => setState(() => _selectedJob = job),
          );
        }
      case "curtidas":
        return CurtidasTab(
          likedJobs: _likedJobs,
          onJobClick: (job) => setState(() => _selectedJob = job),
          onRefresh: _refreshLikes,
        );
      case "matches":
        return MatchesTab(
          matches: _matches,
          onSelectMatch: _openChatWithMatch,
          onRefresh: _refreshMatches,
        );
      case "chat":
        return ChatView(
          match: _activeChatMatch ?? (_matches.isNotEmpty ? _matches.first : mockMatches.first),
          onBack: () => setState(() => _activeTab = "matches"),
        );
      case "perfil":
        return ProfileTab(onLogout: widget.onLogout);
      default:
        return Container();
    }
  }

  Widget _buildCustomBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.gray100),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            id: "vagas",
            label: "Vagas",
            icon: LucideIcons.briefcase,
          ),
          _buildNavItem(
            id: "curtidas",
            label: "Curtidas",
            icon: LucideIcons.heart,
          ),
          _buildNavItem(
            id: "matches",
            label: "Matches",
            icon: LucideIcons.messageCircle,
            showBadge: _matches.isNotEmpty,
          ),
          _buildNavItem(
            id: "perfil",
            label: "Perfil",
            icon: LucideIcons.user,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String id,
    required String label,
    required IconData icon,
    bool showBadge = false,
  }) {
    final isActive = _activeTab == id;
    final color = isActive ? AppColors.primary : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => setState(() => _activeTab = id),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        width: 68,
        height: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
                if (showBadge)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
