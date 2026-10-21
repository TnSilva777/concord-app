# CONCORD — Testes de regressão para chamadas e compartilhamento

Este roteiro é manual. A existência deste arquivo **não** significa que os cenários foram executados ou aprovados.

## Preparação
- Quatro contas reais em navegadores/perfis separados, com acesso à mesma sala.
- Fones em pelo menos dois dispositivos para diferenciar eco acústico de retorno por captura.
- Recarregar a versão publicada do aplicativo em todos os navegadores antes de iniciar.
- No DevTools, conferir erros do console e indicadores de rede; não compartilhar tokens, chaves ou IDs privados.

## Cenários
| Teste | Procedimento | Critério de aprovação |
| --- | --- | --- |
| A — Voz 2 pessoas | A e B entram, alternam fala, mute e unmute. | Ambas ouvem uma à outra uma só vez; indicadores acompanham microfone. |
| B — Voz 3 pessoas | C entra com A e B falando. | A e B continuam se ouvindo e C conversa com ambos. |
| C — Voz 4 pessoas | D entra; todos alternam falas. | Todos permanecem visíveis e nenhuma conexão existente cai. |
| D — Tela com áudio | A compartilha uma aba com áudio explicitamente permitido pelo navegador. | B recebe vídeo e áudio, sem captura indevida da chamada. |
| E — 2 telas | A e C compartilham simultaneamente; B alterna a visualização. | Os dois vídeos seguem independentes; som não toca duplicado. |
| F — Saída | B sai mantendo A, C e D conectados. | Só B desaparece; os restantes continuam listados por mais de 15 segundos. |
| G — Rede instável | D interrompe a internet e retorna. | UI indica reconexão; A, B e C não precisam sair. |
| H — Eco | Com fones, B fala enquanto assiste à aba com áudio de A. | B não escuta o próprio microfone retornando pelo stream de A. |
| I — Detector de voz | Cada participante fala separadamente, depois fica em silêncio. | Só o avatar de quem fala reage; áudio de vídeo não aciona voz. |
| J — Parada individual | A para de compartilhar enquanto C continua. | Somente a mídia de A termina; C segue ao vivo. |

## Para falhas
Registrar cenário, navegador/versão, sistema, quantidade de participantes, quem transmite, se áudio da aba foi autorizado, momento exato, e mensagem de status/erro. Não incluir credenciais.

## Limites conhecidos
A implementação usa WebRTC peer-to-peer com STUN; banda de upload e CPU aumentam com o número de pessoas. STUN não substitui TURN; salas numerosas podem precisar de um SFU. A hospedagem frontend em Vercel não fornece um servidor de mídia persistente automaticamente.
