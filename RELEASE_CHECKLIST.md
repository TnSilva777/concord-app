# CONCORD — critérios para liberar a versão oficial

## Estado atual
- Interface verde e navegação: implementadas; teste visual em desktop/celular pendente.
- Login por Supabase: funcional em testes anteriores; validar recuperação de senha, logout e expiração da sessão.
- Amigos: leitura confirmada após ajuste de GRANT; criação/aceitação/remoção entre duas contas pendente.
- Conversas privadas: interface e cliente implementados; executar `supabase/concord-direct-messages.sql` e testar entre duas contas. Não declarar pronta antes de verificar RLS.
- Salas de voz compartilhadas: schema e interface implementados; criação/exclusão e sincronização entre contas pendentes.
- Chamadas WebRTC: experimentais; precisam de teste real, tratamento de reconexão, TURN e proteção de sinalização/salas privadas.
- Chat público: localStorage, NÃO sincroniza entre pessoas. Aviso explícito na interface.
- Comunidades: ainda dependem de armazenamento local e não são multiusuário.
- Compartilhamento de tela: captura local, não transmissão de tela para amigos.

## Bloqueadores para produção
1. Persistir mensagens públicas e comunidades no Supabase com RLS por participação.
2. Verificar que usuários sem amizade não podem consultar/enviar DMs (testar 3 contas).
3. Proteger acesso e sinalização das chamadas; não tratar nome da sala como autorização.
4. Testar login/logout e isolamento de dados entre contas no mesmo navegador.
5. Testar chamadas em redes diferentes, incluindo NAT restritivo com TURN.
6. Testar desktop, celular, navegação por teclado e erros de rede.
7. Revisar scripts SQL e permissões em ambiente de testes antes de promover `concord-development` para `main`.

## Passo manual ainda necessário
No Supabase SQL Editor, executar `supabase/concord-direct-messages.sql` uma única vez e confirmar sucesso. Depois testar mensagens privadas com duas contas. O código no GitHub não executa SQL automaticamente.

**Não publicar a branch como pronta enquanto houver bloqueadores acima.**
