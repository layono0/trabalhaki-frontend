# Trabalhaki — Aplicativo Mobile (Candidatos)

Aplicativo mobile em **Flutter & Dart** voltado para candidatos da plataforma **Trabalhaki**, oferecendo descoberta transparente de vagas com salário aberto, pontuação de compatibilidade explicada (0–100), registro de interesse, match recíproco e chat pós-match integrado à API oficial (`trabalhaki-backend`).

[![Flutter](https://img.shields.io/badge/Flutter-3.x-393BE7?style=flat-square)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-12152E?style=flat-square)](https://dart.dev/)
[![Tests](https://img.shields.io/badge/Flutter%20Test-30%20testes%20aprovados-0F6B3A?style=flat-square)](https://docs.flutter.dev/testing)

---

## Repositórios do Ecossistema Trabalhaki

| Módulo | Tecnologia | Repositório |
|---|---|---|
| **Aplicativo Mobile (Candidatos)** | Flutter + Dart | [`layono0/trabalhaki-frontend`](https://github.com/layono0/trabalhaki-frontend) |
| **Portal Web (Empresas)** | React 19 + TypeScript + Vite | [`layono0/trabalhaki-web`](https://github.com/layono0/trabalhaki-web) |
| **API REST e Regras de Negócio** | Java 21 + Spring Boot 4.1 | [`layono0/trabalhaki-backend`](https://github.com/layono0/trabalhaki-backend) |

---

## Principais Funcionalidades

- **Boas-Vindas e Identidade Unificada:** tela de apresentação com a marca oficial Trabalhaki e prévia real de cartão de vaga destacando salário aberto e compatibilidade.
- **Cadastro Ágil e Login Autenticado:** criação de conta de candidato com poucos campos obrigatórios, login via JWT + Refresh Token persistido em `SharedPreferences`, alternância de visibilidade de senha e redirecionamento orientativo caso uma empresa tente acessar o app mobile.
- **Descoberta de Vagas por Swipe (`VagasTab`):** cartões interativos com gestos de arrastar (`Passar` / `Tenho interesse`), botão de desfazer último descarte, filtros combináveis (modalidade, estado/UF e salário mínimo) e recuperação resiliente de falhas de rede.
- **Detalhes Transparentes e Compatibilidade Explicada (`JobDetailModal`):** faixa salarial em destaque sem truncamento, requisitos, benefícios e detalhamento ponto a ponto dos 5 critérios da pontuação (habilidades, experiência, salário, modalidade e localização).
- **Aba de Curtidas (`CurtidasTab`):** acompanhamento das vagas em que o candidato demonstrou interesse unilateral (vagas encerradas pela empresa são removidas automaticamente).
- **Matches e Chat Pós-Match (`MatchesTab` & `ChatView`):** modal de celebração sincronizado com o portal web e chat em tempo real (polling de 4s) que respeita a regra de negócio do produto — o envio fica bloqueado com aviso claro até a empresa enviar a primeira mensagem.
- **Perfil Estruturado Reutilizável (`ProfileTab`):** visualização da completude do perfil, foto, preferências e editor completo em tela cheia modal com gerenciamento de competências e seleção de UF.

---

## Arquitetura e Estrutura de Pastas

```text
trabalhaki-frontend/
├── pubspec.yaml                       # Dependências (http, google_fonts, lucide_icons_flutter, shared_preferences, intl)
├── lib/
│   ├── main.dart                      # Entrypoint, gerenciamento de estado de autenticação e tema
│   ├── theme/app_theme.dart           # Paleta oficial WCAG AA, AppRadii (8/12/16px) e InputDecorationTheme
│   ├── models/                        # Modelos tipados (AuthUser, CandidateProfile, Job, MatchItem, ChatMessage)
│   ├── services/api_service.dart      # Integração REST com /api/v1 e renovação automática de token
│   ├── utils/error_messages.dart      # Tradução de erros técnicos em mensagens humanas
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── auth_screen.dart           # Boas-vindas com prévia real de cartão de vaga
│   │   ├── login_screen.dart          # Login alinhado ao Design System (ferramentas dev apenas em kDebugMode)
│   │   ├── signup_screen.dart         # Cadastro ágil de candidato
│   │   ├── main_screen.dart           # Shell de navegação (Vagas, Curtidas, Matches, Perfil)
│   │   └── tabs/                      # VagasTab, CurtidasTab, MatchesTab, ChatView, ProfileTab
│   └── widgets/
│       ├── brand_mark.dart            # Marca geométrica Trabalhaki (CustomPainter)
│       ├── job_card.dart              # Cartão de swipe com borda, elevação e carimbos WCAG AA
│       ├── job_detail_modal.dart      # Detalhes da vaga e explicação de compatibilidade
│       ├── match_modal.dart           # Modal tátil de match (cartões se encontrando)
│       ├── opportunity_tile.dart      # Item reutilizável de listas
│       └── status_view.dart           # Estados vazios e recuperação de erro
└── test/                              # 30 testes unitários e de widget
```

---

## Como Executar Localmente

### Pré-requisitos
- Flutter SDK 3.x (Dart 3.x)
- Back-end `trabalhaki-backend` em execução na porta `8080` (`http://10.0.2.2:8080/api/v1` no emulador Android ou `http://localhost:8080/api/v1` em Web/Desktop)

### Comandos

```bash
# 1. Instalar pacotes Dart/Flutter
flutter pub get

# 2. Executar o aplicativo
flutter run

# 3. Análise estática de código
flutter analyze

# 4. Executar a suíte completa de testes automatizados (30 testes)
flutter test
```

> Em modo debug (`kDebugMode`), a tela de login disponibiliza configuração da URL do servidor e botão de preenchimento rápido da conta de demonstração (`candidato@trabalhaki.com`). Em builds de produção (`release`), ambos ficam ocultos automaticamente.

---

## Qualidade e Testes Automatizados

- **Análise Estática:** `flutter analyze` com 0 erros e 0 alertas.
- **Testes Automatizados (30/30 aprovados):**
  - `api_service_test.dart`: desserialização de modelos e contratos da API.
  - `vagas_swipe_test.dart`: swipes consecutivos sem travamento do deck.
  - `match_modal_test.dart`: exibição, fechamento e ação pós-match.
  - `job_detail_modal_test.dart`: detalhamento de compatibilidade explicada.
  - `discovery_recovery_test.dart`: resiliência a falhas de rede, filtros persistentes, desfazer descarte, bloqueio de input no chat antes da 1ª mensagem da empresa, preservação de rascunhos e recuperação de formulário de perfil.
  - `widget_test.dart`: inicialização do app e transição da splash screen.
