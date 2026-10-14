import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertrabalhaki/models/auth_user.dart';
import 'package:fluttertrabalhaki/models/job.dart';
import 'package:fluttertrabalhaki/models/candidate_profile.dart';
import 'package:fluttertrabalhaki/models/company_profile.dart';
import 'package:fluttertrabalhaki/services/api_service.dart';

void main() {
  group('ApiService and Models Unit Tests', () {
    test('Job model deserialization from backend JobResponse', () {
      final json = {
        "id": 10,
        "companyId": 2,
        "companyName": "Tech Corp Brasil",
        "companyLogoUrl": "https://example.com/logo.png",
        "title": "Desenvolvedor Backend Java",
        "description": "Atuar com microsserviços",
        "minimumSalary": 5000.00,
        "maximumSalary": 7500.00,
        "modality": "REMOTE",
        "city": "São Paulo",
        "state": "SP",
        "country": "Brasil",
        "contractType": "CLT",
        "seniorityLevel": "Pleno",
        "experienceYears": 3,
        "benefits": ["VR", "Plano de Saúde"],
        "skills": [
          {"skillName": "Java", "skillType": "REQUIRED"},
          {"skillName": "Docker", "skillType": "PREFERRED"}
        ],
        "createdAt": "2026-09-24T10:00:00"
      };

      final job = Job.fromJson(json);
      expect(job.id, "10");
      expect(job.title, "Desenvolvedor Backend Java");
      expect(job.company, "Tech Corp Brasil");
      expect(job.type, "Remoto");
      expect(job.location, "São Paulo, SP");
      expect(job.salary, contains("5.000"));
      expect(job.salary, contains("7.500"));
      expect(job.requirements, contains("Java"));
      expect(job.differentials, contains("Docker"));
    });

    test('Job model deserialization from JobRecommendationResponse', () {
      final json = {
        "job": {
          "id": 1,
          "title": "Flutter Developer",
          "companyName": "Inovação SA",
          "minimumSalary": 6000,
          "maximumSalary": 8000,
          "modality": "HYBRID",
          "city": "Campinas",
          "state": "SP",
        },
        "compatibilityScore": 92,
        "explanation": {"skills": "Compatível"}
      };

      final job = Job.fromJson(json);
      expect(job.id, "1");
      expect(job.title, "Flutter Developer");
      expect(job.company, "Inovação SA");
      expect(job.type, "Híbrido");
      expect(job.compatibilityScore, 92);
      expect(job.explanation?["skills"], "Compatível");
    });

    test('MatchItem model deserialization', () {
      final json = {
        "id": 5,
        "jobId": 12,
        "companyName": "Tech Corp",
        "jobTitle": "Java Dev",
        "compatibilityScore": 88,
        "createdAt": "2026-09-24T12:00:00"
      };

      final match = MatchItem.fromJson(json);
      expect(match.id, "5");
      expect(match.jobId, "12");
      expect(match.company, "Tech Corp");
      expect(match.title, "Java Dev");
      expect(match.compatibilityScore, 88);
    });

    test('AuthUser model serialization and role check', () {
      final candidateJson = {
        "id": 1,
        "email": "candidato@trabalhaki.com",
        "role": "CANDIDATE"
      };
      final candidate = AuthUser.fromJson(candidateJson);
      expect(candidate.isCandidate, true);
      expect(candidate.isCompany, false);

      final companyJson = {
        "id": 2,
        "email": "empresa@trabalhaki.com",
        "role": "COMPANY",
        "companyRole": "ADMIN",
        "companyId": 1
      };
      final company = AuthUser.fromJson(companyJson);
      expect(company.isCandidate, false);
      expect(company.isCompany, true);
      expect(company.companyId, 1);
    });

    test('CandidateProfile model serialization', () {
      final json = {
        "id": 1,
        "userId": 2,
        "name": "João Silva",
        "desiredRole": "Desenvolvedor Backend",
        "area": "Tecnologia",
        "experienceYears": 3,
        "city": "São Paulo",
        "state": "SP",
        "minimumSalaryExpectation": 4500.0,
        "preferredModality": "REMOTE",
        "completionPercentage": 85,
        "skills": ["Java", "Spring Boot", "SQL"]
      };

      final profile = CandidateProfile.fromJson(json);
      expect(profile.name, "João Silva");
      expect(profile.desiredRole, "Desenvolvedor Backend");
      expect(profile.location, "São Paulo, SP");
      expect(profile.modality, "Remoto");
      expect(profile.skills.length, 3);
      expect(profile.completionPercentage, 85);
    });

    test('CompanyProfile model deserialization', () {
      final json = {
        "id": 1,
        "name": "Tech Corp Brasil",
        "cnpj": "33000167000101",
        "industry": "Tecnologia",
        "city": "São Paulo",
        "state": "SP",
        "verificationStatus": "VERIFIED",
        "planType": "FREE",
        "activeJobsCount": 3
      };

      final company = CompanyProfile.fromJson(json);
      expect(company.name, "Tech Corp Brasil");
      expect(company.cnpj, "33000167000101");
      expect(company.verificationStatus, "VERIFIED");
      expect(company.activeJobsCount, 3);
    });

    test('extractErrorMessage extracts validationErrors from Spring Boot response', () {
      final backendValidationJson = {
        "timestamp": "2026-10-06T10:00:00",
        "status": 400,
        "error": "Validation Failed",
        "message": "Erros de validação nos campos informados",
        "path": "/api/v1/auth/login",
        "validationErrors": {
          "email": "Email em formato inválido"
        }
      };
      final response = http.Response(
        jsonEncode(backendValidationJson),
        400,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

      final message = ApiService.instance.extractErrorMessage(response);
      expect(message, contains("Email em formato inválido"));
    });

    test('extractErrorMessage extracts unauthorized message from 401 response', () {
      final backendErrorJson = {
        "timestamp": "2026-10-06T10:00:00",
        "status": 401,
        "error": "Unauthorized",
        "message": "Email ou senha inválidos",
        "path": "/api/v1/auth/login"
      };
      final response = http.Response(
        jsonEncode(backendErrorJson),
        401,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

      final message = ApiService.instance.extractErrorMessage(response);
      expect(message, "Email ou senha inválidos");
    });

    test('extractErrorMessage handles business rule conflict error from registration', () {
      final backendConflictJson = {
        "timestamp": "2026-10-08T10:00:00",
        "status": 400,
        "error": "Bad Request",
        "message": "Email já cadastrado no sistema",
        "path": "/api/v1/auth/register-candidate"
      };
      final response = http.Response(
        jsonEncode(backendConflictJson),
        400,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

      final message = ApiService.instance.extractErrorMessage(response);
      expect(message, "Email já cadastrado no sistema");
    });

    test('extractErrorMessage handles CNPJ validation failure from company registration', () {
      final backendCnpjErrorJson = {
        "timestamp": "2026-10-08T10:00:00",
        "status": 400,
        "error": "Bad Request",
        "message": "CNPJ inválido estruturalmente",
        "path": "/api/v1/auth/register-company"
      };
      final response = http.Response(
        jsonEncode(backendCnpjErrorJson),
        400,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

      final message = ApiService.instance.extractErrorMessage(response);
      expect(message, "CNPJ inválido estruturalmente");
    });
  });
}
