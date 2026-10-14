import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';
import '../models/candidate_profile.dart';
import '../models/company_profile.dart';
import '../models/job.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class LikeResult {
  final bool isMatch;
  final String? matchId;
  final String message;

  const LikeResult({
    required this.isMatch,
    this.matchId,
    required this.message,
  });
}

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  String _baseUrl = _defaultBaseUrl();
  String? _accessToken;
  String? _refreshToken;
  AuthUser? _currentUser;

  String get baseUrl => _baseUrl;
  String? get accessToken => _accessToken;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  static String _defaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:8080/api/v1';
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('custom_base_url') ?? _defaultBaseUrl();
    _accessToken = prefs.getString('jwt_access_token');
    _refreshToken = prefs.getString('jwt_refresh_token');

    final userJson = prefs.getString('current_user_json');
    if (userJson != null) {
      try {
        _currentUser = AuthUser.fromJson(jsonDecode(userJson));
      } catch (_) {
        _currentUser = null;
      }
    }

    // Attempt token validation / user refresh if token exists
    if (_accessToken != null) {
      try {
        await refreshCurrentUser();
      } catch (_) {
        // If offline or token expired, keep cached user
      }
    }
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_base_url', _baseUrl);
  }

  Map<String, String> _headers({bool needsAuth = true}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (needsAuth && _accessToken != null) {
      map['Authorization'] = 'Bearer $_accessToken';
    }
    return map;
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  Future<AuthUser> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http
          .post(
            url,
            headers: _headers(needsAuth: false),
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];

        final userMap = data['user'] as Map<String, dynamic>;
        _currentUser = AuthUser.fromJson(userMap);

        final prefs = await SharedPreferences.getInstance();
        if (_accessToken != null) {
          await prefs.setString('jwt_access_token', _accessToken!);
        }
        if (_refreshToken != null) {
          await prefs.setString('jwt_refresh_token', _refreshToken!);
        }
        await prefs.setString('current_user_json', jsonEncode(_currentUser!.toJson()));

        return _currentUser!;
      } else {
        final err = _extractErrorMessage(response);
        throw ApiException(err, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Não foi possível conectar ao servidor ($url): $e');
    }
  }

  Future<AuthUser> registerCandidate(String name, String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/register-candidate');
    try {
      final response = await http
          .post(
            url,
            headers: _headers(needsAuth: false),
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];

        final userMap = data['user'] as Map<String, dynamic>;
        _currentUser = AuthUser.fromJson(userMap);

        final prefs = await SharedPreferences.getInstance();
        if (_accessToken != null) {
          await prefs.setString('jwt_access_token', _accessToken!);
        }
        if (_refreshToken != null) {
          await prefs.setString('jwt_refresh_token', _refreshToken!);
        }
        await prefs.setString('current_user_json', jsonEncode(_currentUser!.toJson()));

        return _currentUser!;
      } else {
        final err = _extractErrorMessage(response);
        throw ApiException(err, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha no cadastro do candidato: $e');
    }
  }

  Future<AuthUser> registerCompany(
      String companyName, String cnpj, String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/register-company');
    try {
      final cleanCnpj = cnpj.replaceAll(RegExp(r'\D'), '');
      final response = await http
          .post(
            url,
            headers: _headers(needsAuth: false),
            body: jsonEncode({
              'companyName': companyName.trim(),
              'cnpj': cleanCnpj,
              'email': email.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];

        final userMap = data['user'] as Map<String, dynamic>;
        _currentUser = AuthUser.fromJson(userMap);

        final prefs = await SharedPreferences.getInstance();
        if (_accessToken != null) {
          await prefs.setString('jwt_access_token', _accessToken!);
        }
        if (_refreshToken != null) {
          await prefs.setString('jwt_refresh_token', _refreshToken!);
        }
        await prefs.setString('current_user_json', jsonEncode(_currentUser!.toJson()));

        return _currentUser!;
      } else {
        final err = _extractErrorMessage(response);
        throw ApiException(err, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha no cadastro da empresa: $e');
    }
  }

  Future<bool> refreshToken() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    final url = Uri.parse('$_baseUrl/auth/refresh');
    try {
      final response = await http
          .post(
            url,
            headers: _headers(needsAuth: false),
            body: jsonEncode({'refreshToken': _refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _accessToken = data['accessToken'];
        if (data['refreshToken'] != null) {
          _refreshToken = data['refreshToken'];
        }
        if (data['user'] != null) {
          _currentUser = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
        }
        final prefs = await SharedPreferences.getInstance();
        if (_accessToken != null) {
          await prefs.setString('jwt_access_token', _accessToken!);
        }
        if (_refreshToken != null) {
          await prefs.setString('jwt_refresh_token', _refreshToken!);
        }
        if (_currentUser != null) {
          await prefs.setString('current_user_json', jsonEncode(_currentUser!.toJson()));
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<AuthUser?> refreshCurrentUser() async {
    if (_accessToken == null) return null;
    final url = Uri.parse('$_baseUrl/auth/me');
    try {
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _currentUser = AuthUser.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_json', jsonEncode(_currentUser!.toJson()));
        return _currentUser;
      } else if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return await refreshCurrentUser();
        } else {
          await logout();
          return null;
        }
      }
    } catch (_) {}
    return _currentUser;
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_access_token');
    await prefs.remove('jwt_refresh_token');
    await prefs.remove('current_user_json');
  }

  // ==========================================
  // JOBS & RECOMMENDATIONS
  // ==========================================

  Future<List<Job>> getJobRecommendations() async {
    final url = Uri.parse('$_baseUrl/recommendations/jobs');
    try {
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        return list.map((item) => Job.fromJson(item as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        // Fallback for general jobs
        return await listActiveJobs();
      } else {
        throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      // Fallback
      return await listActiveJobs();
    }
  }

  Future<List<Job>> listActiveJobs() async {
    final url = Uri.parse('$_baseUrl/jobs');
    try {
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        return list.map((item) => Job.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha ao listar vagas: $e');
    }
  }

  Future<List<Job>> getMyCompanyJobs() async {
    final url = Uri.parse('$_baseUrl/jobs/my');
    try {
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        return list.map((item) => Job.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha ao obter vagas da empresa: $e');
    }
  }

  Future<Job> createJob(Map<String, dynamic> jobData) async {
    final url = Uri.parse('$_baseUrl/jobs');
    try {
      final response = await http.post(url,
          headers: _headers(), body: jsonEncode(jobData));
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        return Job.fromJson(data);
      }
      throw ApiException(_extractErrorMessage(response),
          statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha ao criar vaga: $e');
    }
  }

  Future<Job> updateJob(String jobId, Map<String, dynamic> jobData) async {
    final url = Uri.parse('$_baseUrl/jobs/$jobId');
    try {
      final response = await http.put(url,
          headers: _headers(), body: jsonEncode(jobData));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        return Job.fromJson(data);
      }
      throw ApiException(_extractErrorMessage(response),
          statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha ao atualizar vaga: $e');
    }
  }

  Future<Job> closeJob(String jobId) async {
    final url = Uri.parse('$_baseUrl/jobs/$jobId/close');
    try {
      final response = await http.patch(url, headers: _headers());
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        return Job.fromJson(data);
      }
      throw ApiException(_extractErrorMessage(response),
          statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha ao encerrar vaga: $e');
    }
  }

  // ==========================================
  // LIKES & MATCHES
  // ==========================================

  Future<LikeResult> likeJob(String jobId) async {
    final url = Uri.parse('$_baseUrl/likes/candidate/job/$jobId');
    try {
      final response = await http.post(url, headers: _headers());
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final isMatch = data['isMatch'] == true;
        final matchId = data['matchId']?.toString();
        final message = data['message']?.toString() ?? 'Interesse registrado!';
        return LikeResult(isMatch: isMatch, matchId: matchId, message: message);
      }
      throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro ao curtir vaga: $e');
    }
  }

  Future<List<Job>> getMyLikes() async {
    final url = Uri.parse('$_baseUrl/likes/candidate/my');
    try {
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          if (map.containsKey('job') && map['job'] is Map<String, dynamic>) {
            return Job.fromJson(map['job'] as Map<String, dynamic>);
          }
          return Job.fromJson(map);
        }).toList();
      }
      throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha ao obter curtidas: $e');
    }
  }

  Future<List<MatchItem>> getMyMatches() async {
    final url = Uri.parse('$_baseUrl/matches');
    try {
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        return list.map((item) => MatchItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha ao obter matches: $e');
    }
  }

  Future<MatchItem> getMatchById(String matchId) async {
    final url = Uri.parse('$_baseUrl/matches/$matchId');
    try {
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return MatchItem.fromJson(data);
      }
      throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha ao carregar match: $e');
    }
  }

  // ==========================================
  // CHAT PÓS-MATCH
  // ==========================================

  Future<List<ChatMessage>> getConversation(String matchId) async {
    final url = Uri.parse('$_baseUrl/matches/$matchId/chat');
    try {
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final messages = data['messages'] as List? ?? [];
        return messages.map((m) => ChatMessage.fromJson(
          m as Map<String, dynamic>,
          currentUserId: _currentUser?.id,
        )).toList();
      }
      throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha ao carregar mensagens: $e');
    }
  }

  Future<ChatMessage> sendMessage(String matchId, String content) async {
    final url = Uri.parse('$_baseUrl/matches/$matchId/chat/messages');
    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({'content': content.trim()}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return ChatMessage.fromJson(data, currentUserId: _currentUser?.id);
      }
      throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro ao enviar mensagem: $e');
    }
  }

  // ==========================================
  // CANDIDATE PROFILE
  // ==========================================

  Future<CandidateProfile> getMyCandidateProfile() async {
    final url = Uri.parse('$_baseUrl/candidates/profile/me');
    try {
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return CandidateProfile.fromJson(data);
      }
      throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha ao carregar perfil de candidato: $e');
    }
  }

  Future<CandidateProfile> updateCandidateProfile(CandidateProfile profile) async {
    final url = Uri.parse('$_baseUrl/candidates/profile/me');
    try {
      final response = await http.put(
        url,
        headers: _headers(),
        body: jsonEncode(profile.toJson()),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return CandidateProfile.fromJson(data);
      }
      throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha ao atualizar perfil: $e');
    }
  }

  // ==========================================
  // COMPANY PROFILE
  // ==========================================

  Future<CompanyProfile> getMyCompanyProfile() async {
    final url = Uri.parse('$_baseUrl/companies/me');
    try {
      final response = await http.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return CompanyProfile.fromJson(data);
      }
      throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha ao carregar perfil da empresa: $e');
    }
  }

  // Helper
  String extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map) {
        if (body['validationErrors'] != null && body['validationErrors'] is Map) {
          final valErrors = body['validationErrors'] as Map;
          if (valErrors.isNotEmpty) {
            return valErrors.values.map((v) => v.toString()).join('\n');
          }
        }
        if (body['errors'] != null && body['errors'] is Map) {
          final errs = body['errors'] as Map;
          if (errs.isNotEmpty) {
            return errs.values.map((v) => v.toString()).join('\n');
          }
        }
        if (body['message'] != null && body['message'].toString().trim().isNotEmpty) {
          return body['message'].toString();
        }
        if (body['error'] != null && body['error'].toString().trim().isNotEmpty) {
          return body['error'].toString();
        }
      }
    } catch (_) {}
    return 'Erro HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Erro no servidor'}';
  }

  String _extractErrorMessage(http.Response response) => extractErrorMessage(response);
}
