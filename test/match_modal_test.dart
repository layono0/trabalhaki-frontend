import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrabalhaki/models/job.dart';
import 'package:fluttertrabalhaki/widgets/match_modal.dart';

Job _buildTestJob() {
  return const Job(
    id: '101',
    title: 'Desenvolvedor Flutter Sênior',
    company: 'Tech Inovação',
    logo: 'https://example.com/logo.png',
    location: 'Remoto',
    type: 'Remoto',
    salary: 'R\$ 12.000',
    contract: 'CLT',
    level: 'Sênior',
    experience: '5 anos',
    description: 'Vaga Flutter',
    benefits: ['Plano de Saúde'],
    postedAt: 'Hoje',
    requirements: ['Flutter'],
    differentials: ['Spring Boot'],
    compatibilityScore: 95,
  );
}

void main() {
  testWidgets('showMatchModal opens dialog and can be dismissed via button', (WidgetTester tester) async {
    final job = _buildTestJob();
    bool chatClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showMatchModal(
                    context: context,
                    job: job,
                    candidateName: 'Carlos Silva',
                    candidatePhoto: null,
                    onChatNow: () {
                      chatClicked = true;
                    },
                  );
                },
                child: const Text('Abrir Match'),
              );
            },
          ),
        ),
      ),
    );

    // Dialog is not open yet
    expect(find.text('É um Match!'), findsNothing);

    // Tap to open modal dialog
    await tester.tap(find.text('Abrir Match'));
    await tester.pumpAndSettle();

    // Verify dialog content is presented
    expect(find.text('É um Match!'), findsOneWidget);
    expect(find.text('MATCH PERFEITO'), findsOneWidget);
    expect(find.textContaining('Tech Inovação'), findsOneWidget);
    expect(find.text('Desenvolvedor Flutter Sênior'), findsOneWidget);
    expect(find.text('C'), findsOneWidget); // Monogram fallback for Carlos

    // Tap "Continuar buscando vagas"
    final dismissButton = find.text('Continuar buscando vagas');
    expect(dismissButton, findsOneWidget);
    await tester.ensureVisible(dismissButton);
    await tester.tap(dismissButton);
    await tester.pumpAndSettle();

    // Verify dialog is fully dismissed and not lingering
    expect(find.text('É um Match!'), findsNothing);
    expect(chatClicked, isFalse);
  });

  testWidgets('showMatchModal can be closed via X button', (WidgetTester tester) async {
    final job = _buildTestJob();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showMatchModal(
                    context: context,
                    job: job,
                    candidateName: 'Lucas',
                    candidatePhoto: null,
                    onChatNow: () {},
                  );
                },
                child: const Text('Abrir Match'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir Match'));
    await tester.pumpAndSettle();

    expect(find.text('É um Match!'), findsOneWidget);

    // Tap top-right close icon
    final closeButton = find.byTooltip('Fechar');
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    // Dialog is dismissed
    expect(find.text('É um Match!'), findsNothing);
  });

  testWidgets('showMatchModal triggers onChatNow and dismisses dialog', (WidgetTester tester) async {
    final job = _buildTestJob();
    bool chatClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showMatchModal(
                    context: context,
                    job: job,
                    candidateName: 'Marina',
                    candidatePhoto: null,
                    onChatNow: () {
                      chatClicked = true;
                    },
                  );
                },
                child: const Text('Abrir Match'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir Match'));
    await tester.pumpAndSettle();

    expect(find.text('É um Match!'), findsOneWidget);

    // Tap "Conversar agora"
    await tester.tap(find.text('Conversar agora'));
    await tester.pumpAndSettle();

    // Verify onChatNow was called and dialog dismissed
    expect(chatClicked, isTrue);
    expect(find.text('É um Match!'), findsNothing);
  });
}
