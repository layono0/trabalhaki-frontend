import '../models/job.dart';

final List<Job> mockJobs = [
  const Job(
    id: "1",
    title: "Desenvolvedor Frontend Jr.",
    company: "TechCorp Solutions",
    logo: "https://images.unsplash.com/photo-1549923746-c502d488b3ea?w=100&h=100&fit=crop&auto=format",
    location: "São Paulo, SP",
    type: "Remoto",
    salary: "R\$ 3.500 — R\$ 5.000",
    contract: "CLT",
    level: "Júnior",
    experience: "1–2 anos",
    description:
        "Buscamos um desenvolvedor Frontend Júnior apaixonado por criar interfaces incríveis e fluidas. Você trabalhará diretamente com nosso time de design para implementar soluções inovadoras.",
    benefits: [
      "Vale alimentação",
      "Plano de saúde",
      "Gympass",
      "Auxílio home office",
    ],
    postedAt: "Há 2 dias",
    requirements: ["React", "TypeScript", "Tailwind CSS", "Git"],
    differentials: ["Framer Motion", "Figma", "Next.js"],
  ),
  const Job(
    id: "2",
    title: "Desenvolvedor Backend Java",
    company: "Fintech Banking",
    logo: "https://images.unsplash.com/photo-1556761175-5973dc0f32b7?w=100&h=100&fit=crop&auto=format",
    location: "Curitiba, PR",
    type: "Híbrido",
    salary: "R\$ 6.000 — R\$ 8.000",
    contract: "PJ",
    level: "Pleno",
    experience: "3–5 anos",
    description:
        "Venha fazer parte do time que está revolucionando o sistema bancário brasileiro. Oportunidade para atuar em microsserviços de alta escalabilidade.",
    benefits: ["Bônus anual", "Plano de saúde premium", "Stock Options"],
    postedAt: "Há 5 dias",
    requirements: ["Java 17", "Spring Boot", "AWS", "PostgreSQL"],
    differentials: ["Kafka", "Kubernetes"],
  ),
  const Job(
    id: "3",
    title: "Designer UI/UX",
    company: "Creative Studio",
    logo: "https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=100&h=100&fit=crop&auto=format",
    location: "Rio de Janeiro, RJ",
    type: "Remoto",
    salary: "R\$ 4.500 — R\$ 6.000",
    contract: "CLT",
    level: "Pleno",
    experience: "2–4 anos",
    description:
        "Procuramos um Designer focado em criar experiências memoráveis. Se você ama tipografia, microinterações e usabilidade, essa vaga é sua.",
    benefits: ["Plano de saúde", "Vale refeição", "Orçamento para cursos"],
    postedAt: "Há 1 semana",
    requirements: ["Figma", "Prototipação", "Design System"],
    differentials: ["Framer", "Noções de HTML/CSS"],
  ),
];

final List<MatchItem> mockMatches = [
  const MatchItem(
    id: "m1",
    jobId: "1",
    company: "TechCorp Solutions",
    title: "Desenvolvedor Frontend Jr.",
    logo: "https://images.unsplash.com/photo-1549923746-c502d488b3ea?w=100&h=100&fit=crop&auto=format",
    date: "Match realizado hoje",
  ),
];

final List<ChatMessage> mockMessages = [
  const ChatMessage(
    id: "1",
    sender: "company",
    text:
        "Olá! Vimos seu interesse na vaga de Desenvolvedor Frontend e gostamos muito do seu perfil. Podemos agendar um bate-papo?",
    time: "14:30",
  ),
  const ChatMessage(
    id: "2",
    sender: "candidate",
    text:
        "Olá! Tenho bastante interesse na oportunidade. Podemos marcar para amanhã à tarde?",
    time: "14:35",
  ),
];

class CandidateProfile {
  final String name;
  final String role;
  final String location;
  final String avatarUrl;
  final int completionPercentage;
  final String salaryExpectation;
  final String modality;
  final String contractType;

  const CandidateProfile({
    this.name = "Ana Silva",
    this.role = "Desenvolvedora Frontend Pleno",
    this.location = "São Paulo, SP",
    this.avatarUrl =
        "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop",
    this.completionPercentage = 85,
    this.salaryExpectation = "R\$ 6.000+",
    this.modality = "Remoto / Híbrido",
    this.contractType = "CLT / PJ",
  });
}

const mockCandidate = CandidateProfile();
