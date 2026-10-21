import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fluttertrabalhaki/models/job.dart';
import 'package:fluttertrabalhaki/screens/main_screen.dart';
import 'package:fluttertrabalhaki/screens/tabs/chat_view.dart';
import 'package:fluttertrabalhaki/screens/tabs/vagas_tab.dart';
import 'package:fluttertrabalhaki/screens/tabs/profile_tab.dart';
import 'package:fluttertrabalhaki/services/api_service.dart';

const jobJson = <String, dynamic>{
  'id': '42',
  'title': 'Desenvolvedor Flutter',
  'companyName': 'Empresa real',
  'description': 'Uma oportunidade de trabalho.',
  'modality': 'REMOTE',
  'salary': 'R\$ 8.000',
  'city': 'São Paulo',
  'state': 'SP',
};
http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ApiService apiFor({Future<http.Response> Function(http.Request)? override}) =>
    ApiService.withClient(
      MockClient((request) async {
        if (override != null) return override(request);
        if (request.url.path.endsWith('/recommendations/jobs')) {
          return jsonResponse([jobJson]);
        }
        if (request.url.path.endsWith('/profile/me')) return jsonResponse({});
        return jsonResponse([]);
      }),
    );

Future<void> showMain(WidgetTester tester, ApiService api) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MainScreen(api: api, onLogout: () {}),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('Recommendation failure never falls back to unfiltered jobs', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      return jsonResponse({'message': 'Sem acesso'}, 403);
    });
    addTearDown(client.close);
    final api = ApiService.withClient(client);
    await expectLater(
      api.getJobRecommendations(state: 'SP', modality: 'REMOTE'),
      throwsA(isA<ApiException>()),
    );
    expect(requests, hasLength(1));
    expect(requests.single.queryParameters['state'], 'SP');
  });

  testWidgets('Failed secondary requests do not hide real jobs', (
    tester,
  ) async {
    await showMain(
      tester,
      apiFor(
        override: (request) async {
          if (request.url.path.endsWith('/recommendations/jobs')) {
            return jsonResponse([jobJson]);
          }
          return jsonResponse({'message': 'Indisponível'}, 500);
        },
      ),
    );
    expect(find.text('Desenvolvedor Flutter'), findsOneWidget);
    await tester.tap(find.text('Curtidas'));
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível carregar suas curtidas'),
      findsOneWidget,
    );
  });

  testWidgets('Empty and failed requests never show demonstration jobs', (
    tester,
  ) async {
    var failed = false;
    final api = apiFor(
      override: (request) async {
        if (request.url.path.endsWith('/recommendations/jobs') && failed) {
          return jsonResponse({'message': 'Indisponível'}, 500);
        }
        if (request.url.path.endsWith('/profile/me')) return jsonResponse({});
        return jsonResponse([]);
      },
    );
    await showMain(tester, api);
    expect(find.text('Você viu todas as vagas.'), findsOneWidget);
    expect(find.text('TechCorp Solutions'), findsNothing);
    failed = true;
    await tester.tap(find.text('Atualizar vagas'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar as vagas'), findsOneWidget);
    expect(find.text('TechCorp Solutions'), findsNothing);
  });

  testWidgets('Skipping can be undone, including the final card', (
    tester,
  ) async {
    await showMain(tester, apiFor());
    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();
    expect(find.text('Você viu todas as vagas.'), findsOneWidget);
    await tester.tap(find.byTooltip('Desfazer último descarte'));
    await tester.pumpAndSettle();
    expect(find.text('Desenvolvedor Flutter'), findsOneWidget);
  });

  testWidgets('An interrupted swipe can be followed by another swipe', (
    tester,
  ) async {
    await showMain(tester, apiFor());
    final card = find.byKey(const ValueKey('job_42'));
    final gesture = await tester.startGesture(tester.getCenter(card));
    await gesture.moveBy(const Offset(-50, 0));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(card, findsOneWidget);
    await tester.drag(card, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Você viu todas as vagas.'), findsOneWidget);
  });

  testWidgets('A failed like restores the job without adding a saved like', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    var likeCalls = 0;
    final api = apiFor(
      override: (request) async {
        if (request.method == 'POST') {
          likeCalls++;
          return pending.future;
        }
        if (request.url.path.endsWith('/recommendations/jobs')) {
          return jsonResponse([jobJson]);
        }
        if (request.url.path.endsWith('/profile/me')) return jsonResponse({});
        return jsonResponse([]);
      },
    );
    await showMain(tester, api);
    await tester.tap(find.text('Tenho interesse'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(likeCalls, 1);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Enviando…'),
    );
    expect(button.onPressed, isNull);
    pending.complete(jsonResponse({'message': 'Falhou'}, 500));
    await tester.pumpAndSettle();
    expect(find.text('Desenvolvedor Flutter'), findsOneWidget);
    expect(find.textContaining('A vaga voltou para a lista.'), findsOneWidget);
    await tester.tap(find.text('Curtidas'));
    await tester.pumpAndSettle();
    expect(find.text('Desenvolvedor Flutter'), findsNothing);
    expect(find.text('Explorar vagas'), findsOneWidget);
  });

  testWidgets(
    'Filters survive navigation and an empty result offers recovery',
    (tester) async {
      final requests = <Uri>[];
      final api = apiFor(
        override: (request) async {
          if (request.url.path.endsWith('/recommendations/jobs')) {
            requests.add(request.url);
            return jsonResponse(
              request.url.queryParameters.isEmpty ? [jobJson] : [],
            );
          }
          if (request.url.path.endsWith('/profile/me')) return jsonResponse({});
          return jsonResponse([]);
        },
      );
      await showMain(tester, api);
      await tester.tap(find.byTooltip('Filtrar vagas'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Remoto'));
      await tester.tap(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma vaga com esses filtros'), findsOneWidget);
      expect(requests.last.queryParameters['modality'], 'REMOTE');
      await tester.tap(find.text('Curtidas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vagas'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<VagasTab>(find.byType(VagasTab)).activeModality,
        'REMOTE',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Limpar filtros'));
      await tester.pumpAndSettle();
      expect(requests.last.queryParameters, isEmpty);
      expect(find.text('Desenvolvedor Flutter'), findsOneWidget);
    },
  );

  testWidgets('Compact cards remain usable with large text and long content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final longJob = Job.fromJson({
      ...jobJson,
      'title': 'Desenvolvedor Flutter para produtos digitais e plataformas de serviços com equipes distribuídas',
      'companyName': 'Empresa de tecnologia com um nome bastante longo para testar a interface',
      'location': 'São José dos Campos, São Paulo, Brasil',
    });
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: VagasTab(
            jobs: [longJob],
            onSwipe: (_, _) {},
            onCardClick: (_) {},
            onResetJobs: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Ver detalhes da vaga'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('A confirmed like appears in saved jobs', (tester) async {
    final api = apiFor(
      override: (request) async {
        if (request.method == 'POST') {
          return jsonResponse({'isMatch': false}, 201);
        }
        if (request.url.path.endsWith('/recommendations/jobs')) {
          return jsonResponse([jobJson]);
        }
        if (request.url.path.endsWith('/profile/me')) return jsonResponse({});
        return jsonResponse([]);
      },
    );
    await showMain(tester, api);
    await tester.tap(find.text('Tenho interesse'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Interesse registrado.'), findsOneWidget);
    await tester.tap(find.text('Curtidas'));
    await tester.pumpAndSettle();
    expect(find.text('Desenvolvedor Flutter'), findsOneWidget);
  });

  testWidgets('Chat drafts survive returning to the match list', (
    tester,
  ) async {
    final api = apiFor(
      override: (request) async {
        if (request.url.path.endsWith('/recommendations/jobs')) {
          return jsonResponse([]);
        }
        if (request.url.path.endsWith('/profile/me')) return jsonResponse({});
        if (request.url.path.endsWith('/matches')) {
          return jsonResponse([
            {
              'id': 'm1',
              'jobId': '42',
              'jobTitle': 'Flutter',
              'companyName': 'Empresa',
            },
          ]);
        }
        if (request.url.path.endsWith('/chat')) {
          return jsonResponse({'messages': []});
        }
        return jsonResponse([]);
      },
    );
    await showMain(tester, api);
    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir conversa'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Quero saber mais sobre a vaga',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Seus matches'), findsOneWidget);
    await tester.tap(find.text('Abrir conversa'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Quero saber mais sobre a vaga',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Failed profile save preserves the form and can be retried', (
    tester,
  ) async {
    var fail = true;
    final api = apiFor(
      override: (request) async {
        if (request.method == 'PUT') {
          if (fail) return jsonResponse({'message': 'Falhou'}, 500);
          return jsonResponse({'id': 1, 'name': 'Nome atualizado'});
        }
        return jsonResponse({'id': 1, 'name': 'Nome original', 'skills': []});
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileTab(api: api, onLogout: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar Perfil'));
    await tester.pumpAndSettle();
    final nameField = find.widgetWithText(TextField, 'Nome completo');
    await tester.enterText(nameField, 'Nome atualizado');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar Perfil Profissional'), findsOneWidget);
    expect(
      tester.widget<TextField>(nameField).controller!.text,
      'Nome atualizado',
    );
    expect(find.textContaining('Seus dados foram mantidos'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar Perfil Profissional'), findsNothing);
    expect(find.text('Nome atualizado'), findsOneWidget);
  });

  const match = MatchItem(
    id: 'm1',
    jobId: '42',
    title: 'Flutter',
    company: 'Empresa',
    logo: '',
    date: 'Hoje',
  );
  testWidgets('Chat preserves a failed draft and retries successfully', (
    tester,
  ) async {
    var fail = true;
    var posts = 0;
    final api = apiFor(
      override: (request) async {
        if (request.method == 'POST') {
          posts++;
          if (fail) return jsonResponse({'message': 'Falhou'}, 500);
          return jsonResponse({
            'id': 'msg1',
            'content': 'Olá, tenho interesse!',
            'sender': 'candidate',
          }, 201);
        }
        return jsonResponse({'messages': []});
      },
    );
    String draft = '';
    await tester.pumpWidget(
      MaterialApp(
        home: ChatView(
          match: match,
          api: api,
          onBack: () {},
          onDraftChanged: (value) => draft = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Olá, tenho interesse!');
    await tester.tap(find.byTooltip('Enviar mensagem'));
    await tester.pumpAndSettle();
    expect(draft, 'Olá, tenho interesse!');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      draft,
    );
    expect(find.textContaining('Seu texto foi mantido.'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Reenviar'));
    await tester.pumpAndSettle();
    expect(posts, 2);
    expect(draft, isEmpty);
    expect(find.text('Olá, tenho interesse!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Chat load failure is distinct from an empty conversation', (
    tester,
  ) async {
    final api = apiFor(
      override: (_) async => jsonResponse({'message': 'Falhou'}, 500),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChatView(match: match, api: api, onBack: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A conversa não carregou'), findsOneWidget);
    expect(find.text('Inicie a conversa!'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
