import 'package:intl/intl.dart';

class Job {
  final String id;
  final String title;
  final String company;
  final String logo;
  final String location;
  final String type;
  final String salary;
  final String contract;
  final String level;
  final String experience;
  final String description;
  final List<String> benefits;
  final String postedAt;
  final List<String> requirements;
  final List<String> differentials;
  final int? compatibilityScore;
  final int? companyId;
  final Map<String, dynamic>? explanation;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.logo,
    required this.location,
    required this.type,
    required this.salary,
    required this.contract,
    required this.level,
    required this.experience,
    required this.description,
    required this.benefits,
    required this.postedAt,
    required this.requirements,
    required this.differentials,
    this.compatibilityScore,
    this.companyId,
    this.explanation,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    // If wrapped in recommendation response: { job: {...}, compatibilityScore: 85, explanation: {...} }
    final Map<String, dynamic> raw =
        json.containsKey('job') && json['job'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['job'])
            : json;

    final int? score = json['compatibilityScore'] is int
        ? json['compatibilityScore']
        : (int.tryParse(json['compatibilityScore']?.toString() ?? ''));

    final Map<String, dynamic>? expl =
        json['explanation'] is Map ? Map<String, dynamic>.from(json['explanation']) : null;

    // Format modality
    String modalityStr = (raw['modality'] ?? raw['type'] ?? 'REMOTE').toString().toUpperCase();
    if (modalityStr == 'REMOTE') {
      modalityStr = 'Remoto';
    } else if (modalityStr == 'HYBRID') {
      modalityStr = 'Híbrido';
    } else if (modalityStr == 'ONSITE') {
      modalityStr = 'Presencial';
    }

    // Format location
    String loc = '';
    final city = raw['city']?.toString() ?? '';
    final state = raw['state']?.toString() ?? '';
    if (city.isNotEmpty && state.isNotEmpty) {
      loc = '$city, $state';
    } else if (city.isNotEmpty) {
      loc = city;
    } else if (state.isNotEmpty) {
      loc = state;
    } else {
      loc = raw['location']?.toString() ?? 'Brasil';
    }

    // Format salary
    String salaryStr = raw['salary']?.toString() ?? '';
    if (salaryStr.isEmpty && raw['minimumSalary'] != null && raw['maximumSalary'] != null) {
      final minSal = num.tryParse(raw['minimumSalary'].toString()) ?? 0;
      final maxSal = num.tryParse(raw['maximumSalary'].toString()) ?? 0;
      final f = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);
      salaryStr = '${f.format(minSal)} — ${f.format(maxSal)}';
    } else if (salaryStr.isEmpty) {
      salaryStr = 'A combinar';
    }

    // Format skills
    List<String> reqs = [];
    List<String> diffs = [];
    if (raw['skills'] is List) {
      for (var s in raw['skills']) {
        if (s is Map) {
          final skillName = s['skillName']?.toString() ?? '';
          final skillType = (s['skillType'] ?? s['type'] ?? 'REQUIRED').toString().toUpperCase();
          if (skillType == 'REQUIRED') {
            reqs.add(skillName);
          } else {
            diffs.add(skillName);
          }
        } else if (s is String) {
          reqs.add(s);
        }
      }
    } else {
      if (raw['requirements'] is List) {
        reqs = List<String>.from(raw['requirements'].map((e) => e.toString()));
      }
      if (raw['differentials'] is List) {
        diffs = List<String>.from(raw['differentials'].map((e) => e.toString()));
      }
    }

    // Format benefits
    List<String> bList = [];
    if (raw['benefits'] is List) {
      bList = List<String>.from(raw['benefits'].map((e) => e.toString()));
    }

    // Format posted date
    String postedStr = raw['postedAt']?.toString() ?? '';
    if (postedStr.isEmpty && raw['createdAt'] != null) {
      try {
        final dt = DateTime.parse(raw['createdAt'].toString());
        final diff = DateTime.now().difference(dt);
        if (diff.inDays == 0) {
          postedStr = 'Hoje';
        } else if (diff.inDays == 1) {
          postedStr = 'Há 1 dia';
        } else {
          postedStr = 'Há ${diff.inDays} dias';
        }
      } catch (_) {
        postedStr = 'Recente';
      }
    } else if (postedStr.isEmpty) {
      postedStr = 'Recente';
    }

    final logoUrl = (raw['companyLogoUrl'] ?? raw['logo'])?.toString();
    final defaultLogo =
        "https://images.unsplash.com/photo-1549923746-c502d488b3ea?w=100&h=100&fit=crop&auto=format";

    return Job(
      id: raw['id']?.toString() ?? '',
      title: raw['title']?.toString() ?? 'Vaga sem título',
      company: (raw['companyName'] ?? raw['company'])?.toString() ?? 'Empresa',
      logo: (logoUrl != null && logoUrl.isNotEmpty) ? logoUrl : defaultLogo,
      location: loc,
      type: modalityStr,
      salary: salaryStr,
      contract: raw['contractType']?.toString() ?? raw['contract']?.toString() ?? 'CLT',
      level: raw['seniorityLevel']?.toString() ?? raw['level']?.toString() ?? 'Pleno',
      experience: raw['experienceYears'] != null
          ? "${raw['experienceYears']} anos"
          : (raw['experience']?.toString() ?? '1–2 anos'),
      description: raw['description']?.toString() ?? '',
      benefits: bList,
      postedAt: postedStr,
      requirements: reqs.isNotEmpty ? reqs : ["Java", "Spring Boot", "Git"],
      differentials: diffs,
      compatibilityScore: score,
      companyId: raw['companyId'] is int ? raw['companyId'] : int.tryParse(raw['companyId']?.toString() ?? ''),
      explanation: expl,
    );
  }
}

class MatchItem {
  final String id;
  final String jobId;
  final String company;
  final String title;
  final String logo;
  final String date;
  final String? candidateId;
  final String? candidateName;
  final String? candidatePhotoUrl;
  final int? compatibilityScore;

  const MatchItem({
    required this.id,
    required this.jobId,
    required this.company,
    required this.title,
    required this.logo,
    required this.date,
    this.candidateId,
    this.candidateName,
    this.candidatePhotoUrl,
    this.compatibilityScore,
  });

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    String dateStr = json['date']?.toString() ?? '';
    if (dateStr.isEmpty && json['createdAt'] != null) {
      try {
        final dt = DateTime.parse(json['createdAt'].toString());
        final f = DateFormat('dd/MM/yyyy HH:mm');
        dateStr = 'Match em ${f.format(dt)}';
      } catch (_) {
        dateStr = 'Match recente';
      }
    } else if (dateStr.isEmpty) {
      dateStr = 'Match recente';
    }

    final defaultLogo =
        "https://images.unsplash.com/photo-1549923746-c502d488b3ea?w=100&h=100&fit=crop&auto=format";
    final rawLogo = (json['companyLogoUrl'] ?? json['logo'])?.toString();

    return MatchItem(
      id: json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      company: (json['companyName'] ?? json['company'])?.toString() ?? 'Empresa parceira',
      title: (json['jobTitle'] ?? json['title'])?.toString() ?? 'Vaga em aberto',
      logo: (rawLogo != null && rawLogo.isNotEmpty) ? rawLogo : defaultLogo,
      date: dateStr,
      candidateId: json['candidateId']?.toString(),
      candidateName: json['candidateName']?.toString(),
      candidatePhotoUrl: json['candidatePhotoUrl']?.toString(),
      compatibilityScore: json['compatibilityScore'] is int
          ? json['compatibilityScore']
          : int.tryParse(json['compatibilityScore']?.toString() ?? ''),
    );
  }
}

class ChatMessage {
  final String id;
  final String sender; // 'candidate' or 'company'
  final String text;
  final String time;
  final int? senderId;
  final String? senderName;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    this.senderId,
    this.senderName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    String timeStr = json['time']?.toString() ?? '';
    if (timeStr.isEmpty && json['createdAt'] != null) {
      try {
        final dt = DateTime.parse(json['createdAt'].toString());
        timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (_) {
        timeStr = '';
      }
    }

    final rawSenderId = json['senderId'] is int
        ? json['senderId']
        : int.tryParse(json['senderId']?.toString() ?? '');

    String senderType = json['sender']?.toString() ?? '';
    if (senderType.isEmpty) {
      if (currentUserId != null && rawSenderId != null) {
        senderType = (rawSenderId == currentUserId) ? 'candidate' : 'company';
      } else {
        senderType = 'company';
      }
    }

    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sender: senderType,
      text: (json['content'] ?? json['text'])?.toString() ?? '',
      time: timeStr,
      senderId: rawSenderId,
      senderName: json['senderName']?.toString(),
    );
  }
}
