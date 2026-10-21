---
target: /impeccable critique — fluxo de vagas do Trabalhaki
total_score: 18
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:/home/layono/Documentos/Trbalhaki/trabalhaki-frontend/lib/screens/main_screen.dart"
target_fingerprint: "sha256:4b153b60f91315f6ead5ff60c9a3e69f266c2a7d8c68a1684c31d535d0585619"
target_path: /home/layono/Documentos/Trbalhaki/trabalhaki-frontend/lib/screens/main_screen.dart
timestamp: 2026-10-21T00-32-35Z
slug: lib-screens-main-screen-dart
closed: true
---
Método: revisão de design Flutter; detector de HTML não aplicável à interface nativa renderizada em canvas.

Escopo: MainScreen, descoberta de vagas, curtidas e chat. Prévia isolada dos componentes atuais com fallback de demonstração, vista em 390×844 e 360×640. Fluxos autenticados e leitores de tela não foram exercitados. Notas são estimativas heurísticas, não resultado de teste com usuários.

## Identidade e impressão
A linguagem visual é coerente, mas a composição depende bastante do padrão de aplicativos de encontros: baralho, coração, estrela e matches. Salário e modalidade dão contexto de emprego; a interface ainda explica pouco o significado do interesse e da compatibilidade. O maior ganho agora é tornar cada ação confiável e compreensível.

## Saúde de design
| Heurística | Nota /4 | Evidência |
|---|---:|---|
| Visibilidade do estado | 1 | Curtida local pode permanecer após falha silenciosa. |
| Correspondência com o mundo real | 3 | Salário, local e contrato claros; match e superlike exigem interpretação. |
| Controle e liberdade | 1 | Descarte sem desfazer na descoberta. |
| Consistência | 3 | Paleta, componentes e navegação coerentes. |
| Prevenção de erros | 2 | Filtros estruturados; ações de interesse sem reversão visível. |
| Reconhecimento | 2 | Navegação rotulada; ações centrais apenas por ícones. |
| Eficiência | 1 | Comparação depende de lembrar cards anteriores. |
| Estética e foco | 3 | Uma vaga em foco; ritmo vertical irregular. |
| Recuperação de erros | 1 | Mensagem digitada é apagada antes da confirmação de envio. |
| Ajuda | 1 | Falta explicação junto às ações e ao estado vazio. |
| Total | 18/40 | Fraco; problemas importantes no fluxo principal. |

## Acertos
- Uma vaga por vez reduz a disputa de atenção.
- Salário, localização, modalidade e contrato permitem triagem rápida.
- Navegação inferior com quatro destinos rotulados e ações ao alcance do polegar.

## Prioridades
1. [P1] A interface disfarça falhas como atividade real. MainScreen substitui respostas vazias ou falhas por mockJobs e, em falha inicial, mockMatches. Curtidas entram na lista antes da resposta e não são revertidas. Isso compromete a confiança de quem procura emprego. Separar demonstração, vazio e erro; indicar pendência e permitir nova tentativa. Comando: /impeccable harden. Referência: lib/screens/main_screen.dart:60, 67, 134.
2. [P1] O chat perde o texto quando o envio falha. O campo é limpo antes da requisição; a falha gera aviso sem restaurar o rascunho. Manter a mensagem até confirmar ou exibir uma mensagem pendente com tentar novamente. Comando: /impeccable harden. Referência: lib/screens/tabs/chat_view.dart:86.
3. [P1] Os controles pedem adivinhação e prometem uma distinção inexistente. X, estrela e coração não têm rótulos visíveis; a estrela anuncia Superlike enviado e usa o mesmo caminho da curtida. Rotular Pular e Tenho interesse; retirar o superlike até existir comportamento próprio; fornecer semântica de botão e foco. Comando: /impeccable clarify. Referência: lib/screens/tabs/vagas_tab.dart:401, 517.
4. [P2] Um descarte acidental não tem recuperação imediata. O card sai da lista sem histórico ou desfazer; atualizar vagas não recupera precisamente a decisão anterior. Oferecer Desfazer para a última ação e explicar a diferença entre curtir e candidatar-se. Comando: /impeccable harden. Referência: lib/screens/main_screen.dart:134.
5. [P2] O ritmo do card muda demais com a altura. Em 390×844 sobra um grande vazio antes do resumo; em 360×640 o resumo encosta nas etiquetas. O Spacer absorve todo o espaço. Definir espaçamentos previsíveis, permitir rolagem quando necessário e sinalizar Ver detalhes. Comando: /impeccable layout. Referência: lib/widgets/job_card.dart:422.

## Carga cognitiva e jornada emocional
Carga moderada: três falhas no checklist (agrupamento, limite de escolhas e memória entre cards). O filtro salarial apresenta cinco opções. Comparar vagas exige lembrar a anterior. O pico positivo do match perde força quando não há clareza sobre persistência; o maior vale é perder a mensagem ao contatar a empresa.

## Personas
- Primeiro acesso: pode confundir interesse com candidatura e não entender o ganho do superlike.
- Uso com leitor de tela: GestureDetector e ícones centrais sem nomes semânticos explícitos exigem validação; risco identificado no código, sem teste assistivo.
- Celular com conexão instável: curtidas sem confirmação e perda de rascunho tornam a retomada insegura.

## Observações menores
O vazio Você viu todas as vagas também aparece quando filtros retornam zero; oferecer Limpar filtros. O badge de Matches indica existência de matches, não necessariamente conversa nova. A navegação inferior usa cinza claro e fonte de 11; validar contraste e escala de texto. Não há PRODUCT.md ou DESIGN.md para confrontar intenção de marca.

## Questões de design
Que informação justifica a compatibilidade e ajuda a decidir? O que a empresa recebe quando alguém toca em Tenho interesse?
