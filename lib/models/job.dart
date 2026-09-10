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
  });
}

class MatchItem {
  final String id;
  final String jobId;
  final String company;
  final String title;
  final String logo;
  final String date;

  const MatchItem({
    required this.id,
    required this.jobId,
    required this.company,
    required this.title,
    required this.logo,
    required this.date,
  });
}

class ChatMessage {
  final String id;
  final String sender; // 'candidate' or 'company'
  final String text;
  final String time;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
  });
}
