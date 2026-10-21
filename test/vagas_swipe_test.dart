import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrabalhaki/models/job.dart';
import 'package:fluttertrabalhaki/screens/tabs/vagas_tab.dart';
import 'package:fluttertrabalhaki/widgets/job_card.dart';

Job _buildTestJob(String id, String title) {
  return Job(
    id: id,
    title: title,
    company: 'Empresa $id',
    logo: 'https://example.com/logo$id.png',
    location: 'São Paulo, SP',
    type: 'Remoto',
    salary: 'R\$ 8.000',
    contract: 'CLT',
    level: 'Pleno',
    experience: '2 anos',
    description: 'Descrição da vaga $id',
    benefits: const ['VR', 'VA'],
    postedAt: 'Hoje',
    requirements: const ['Flutter', 'Dart'],
    differentials: const ['Spring Boot'],
    compatibilityScore: 90,
  );
}

void main() {
  testWidgets('Consecutive card swipes do not freeze the deck', (WidgetTester tester) async {
    final jobs = [
      _buildTestJob('1', 'Vaga Flutter 1'),
      _buildTestJob('2', 'Vaga Flutter 2'),
      _buildTestJob('3', 'Vaga Flutter 3'),
    ];

    final swipedJobs = <Map<String, dynamic>>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return VagasTab(
                jobs: jobs,
                onSwipe: (job, direction) {
                  swipedJobs.add({'id': job.id, 'dir': direction});
                  setState(() {
                    jobs.removeWhere((j) => j.id == job.id);
                  });
                },
                onCardClick: (_) {},
                onResetJobs: () {},
              );
            },
          ),
        ),
      ),
    );

    // Initial check: top card is Vaga Flutter 1
    expect(find.text('Vaga Flutter 1'), findsOneWidget);
    expect(find.text('Vaga Flutter 2'), findsOneWidget);

    // 1. Swipe top card to the right by drag gesture
    final firstCardFinder = find.byKey(const ValueKey('job_1'));
    expect(firstCardFinder, findsOneWidget);

    await tester.drag(firstCardFinder, const Offset(300, 0));
    await tester.pumpAndSettle();

    // Verify first card was swiped right and removed
    expect(swipedJobs.length, 1);
    expect(swipedJobs[0]['id'], '1');
    expect(swipedJobs[0]['dir'], SwipeDirection.right);
    expect(find.byKey(const ValueKey('job_1')), findsNothing);

    // 2. Card 2 should now be front and interactive (NO FREEZE!)
    final secondCardFinder = find.byKey(const ValueKey('job_2'));
    expect(secondCardFinder, findsOneWidget);
    expect(find.text('Vaga Flutter 2'), findsOneWidget);

    // Swipe card 2 to the left by drag gesture
    await tester.drag(secondCardFinder, const Offset(-300, 0));
    await tester.pumpAndSettle();

    // Verify second card was swiped left and removed
    expect(swipedJobs.length, 2);
    expect(swipedJobs[1]['id'], '2');
    expect(swipedJobs[1]['dir'], SwipeDirection.left);
    expect(find.byKey(const ValueKey('job_2')), findsNothing);

    // 3. Card 3 should now be front and can be swiped using action button
    final thirdCardFinder = find.byKey(const ValueKey('job_3'));
    expect(thirdCardFinder, findsOneWidget);

    // Tap the like button (heart icon)
    final likeButtonFinder = find.byIcon(Icons.favorite);
    expect(likeButtonFinder, findsOneWidget);
    await tester.tap(likeButtonFinder);
    await tester.pumpAndSettle();

    // Verify third card was swiped right via button
    expect(swipedJobs.length, 3);
    expect(swipedJobs[2]['id'], '3');
    expect(swipedJobs[2]['dir'], SwipeDirection.right);
    expect(find.byKey(const ValueKey('job_3')), findsNothing);

    // 4. Empty state is shown
    expect(find.text('Você viu todas as vagas.'), findsOneWidget);
  });
}
