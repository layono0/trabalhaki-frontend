import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrabalhaki/models/job.dart';
import 'package:fluttertrabalhaki/widgets/job_detail_modal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('JobDetailModal renders explainable compatibility breakdown', (WidgetTester tester) async {
    const jobWithExplanation = Job(
      id: 'job-exp-1',
      title: 'Desenvolvedor Flutter Sênior',
      company: 'App Studios Inc.',
      logo: 'https://example.com/logo.png',
      location: 'São Paulo, SP',
      type: 'Remoto',
      salary: 'R\$ 10.000',
      contract: 'CLT',
      level: 'Sênior',
      experience: '3 anos',
      description: 'Desenvolvimento de aplicativos móveis com Flutter e Dart.',
      benefits: ['Plano de Saúde', 'VR'],
      postedAt: 'Há 2 dias',
      requirements: ['Flutter', 'Dart', 'Clean Architecture'],
      differentials: ['Spring Boot'],
      compatibilityScore: 92,
      explanation: {
        'skills': 'Compatibilidade de 90% nas habilidades exigidas (Flutter, Dart)',
        'experience': 'Experiência de 4 anos atende integralmente ao requisito de 3 anos',
        'salary': 'Pretensão dentro da faixa salarial da oportunidade',
        'modality': 'Modalidade Remota compatível com suas preferências',
        'location': 'Sem restrição geográfica aplicável',
      },
    );

    bool closed = false;
    bool matched = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobDetailModal(
            job: jobWithExplanation,
            onClose: () => closed = true,
            onMatch: (_) => matched = true,
          ),
        ),
      ),
    );

    // Verify Title and Company
    expect(find.text('Desenvolvedor Flutter Sênior'), findsOneWidget);
    expect(find.text('App Studios Inc.'), findsOneWidget);

    // Verify Explainable Compatibility Header and Score
    expect(find.text('Compatibilidade'), findsOneWidget);
    expect(find.text('92% match'), findsOneWidget);

    // Verify specific explainable criteria
    expect(find.text('Habilidades'), findsOneWidget);
    expect(find.textContaining('Compatibilidade de 90% nas habilidades'), findsOneWidget);
    expect(find.text('Experiência'), findsOneWidget);
    expect(find.textContaining('Experiência de 4 anos atende'), findsOneWidget);
    expect(find.text('Modalidade'), findsWidgets); // grid + explanation
    expect(find.textContaining('Modalidade Remota compatível'), findsOneWidget);

    // Verify closing action
    await tester.tap(find.byIcon(LucideIcons.chevronDown));
    await tester.pumpAndSettle();
    expect(closed, isTrue);

    // Verify interest action
    final interestButton = find.text('Tenho interesse');
    expect(interestButton, findsOneWidget);
    await tester.tap(interestButton);
    await tester.pumpAndSettle();
    expect(matched, isTrue);
  });
}
