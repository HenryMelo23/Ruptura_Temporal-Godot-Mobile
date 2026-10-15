# Progresso permanente e recuperação de conta

## Fonte de verdade e fluxo

O backend do relay é a fonte autoritativa do progresso permanente. O cliente
mantém um cache assinado para leitura rápida/offline e uma fila de eventos;
ele não é capaz de elevar o snapshot canônico sozinho.

```text
ação validada no jogo
        |
        v
evento versionado + id + device_id + sequência local
        |
        +-- sem rede --> cache assinado / fila offline (máx. 240)
        |                         |
        |                         +-- cheia --> evento vai para "Em revisão"; nada é apagado
        v
HTTPS obrigatório --> relay autoritativo --> validação + idempotência + ordem por dispositivo
                                      |                         |
                                      |                         +-- recusado --> cliente mantém registro em revisão
                                      v
                         snapshot canônico versionado
                                      |
                                      v
                   cache local e tela "Progresso salvo"
```

O snapshot remoto cobre desbloqueios, métricas de progresso, níveis de
espectro e moedas espectrais. Progresso de uma run interrompida continua sendo
um save local separado; ele não é promovido automaticamente a progresso
permanente.

## Identidade e recuperação

- A criação gera um código aleatório de 128 bits (`16` bytes, exibido em grupos
  de quatro caracteres). O relay armazena somente o hash SHA-256 da forma
  canônica do código.
- A tela **Progresso salvo** permite recuperar antes de criar um perfil novo;
  apelido e identificador local não são mecanismos de recuperação.
- O código aparece apenas na sessão de criação e pode ser copiado. Ele não é
  gravado no perfil nem no cache local, não é escrito em log e não entra em
  telemetria. O jogador precisa guardá-lo fora do aparelho.
- Um resgate emite um novo token de sessão. Não há enumeração de contas: código
  ausente, inválido ou desconhecido responde com a mesma mensagem genérica.
- Tokens são comparados em tempo constante e os pedidos de criar, recuperar e
  enviar eventos têm limitação temporária por IP e por identidade. Esses
  limites são memória de processo; uma futura camada compartilhada deve ser
  usada se o relay for horizontalizado.

### Compatibilidade

O servidor aceita registros de progresso schema/evento `1` e `2`; novos
registros são emitidos como `2`. O cache local também lê o schema `1` assinado
e o salva novamente como `2`. Eventos `2` usam `device_id` derivado do segredo
de instalação e uma sequência estrita por dispositivo. A sequência impede que
um evento fora de ordem ou repetido vire crédito adicional. IDs de evento
mantêm idempotência em reenvios e reconexões.

Os campos de save existentes e os identificadores de cartas/manifestações não
foram renomeados. Uma resposta remota com versão inferior ao último snapshot
aceito é recusada pelo cliente.

## Conflitos e validação econômica

Desbloqueios e métricas são monotônicos depois de validados pelo backend.
Moedas espectrais e upgrades usam um pequeno ledger: núcleo recebido aumenta o
saldo dentro do limite do evento; upgrade só aceita o próximo nível conhecido
e só debita se o saldo canônico cobrir o custo. Um cliente não decide preço,
saldo ou resultado final.

O relay devolve `accepted`, `duplicate` e `rejected_events` separados. Eventos
recusados saem da fila de envio e entram em **Em revisão** com motivo; eles não
são descartados silenciosamente. A fila normal é limitada a 240 itens; ao
atingir o limite, o novo evento também fica em revisão sem remover um evento
antigo.

## Durabilidade no relay

`PLAYER_PROGRESS_PATH` é tratado como dado crítico:

1. leitura primária válida: modo `healthy`;
2. primário inválido e `.bak` válida: carrega a cópia, modo `recovered_backup`;
3. primário e backup ausentes: store novo, permitido somente para instalação
   realmente nova;
4. primário e backup inválidos: modo `protected_read_only`, criação e mutação
   retornam `503`, sem sobrescrever os arquivos.

O write usa arquivo temporário no mesmo filesystem, `fsync`, rename e backup da
última cópia conhecida boa. Um write posterior validado reconstrói o primário a
partir do backup e volta o modo a `healthy`. O endpoint `/health` expõe somente
o modo do store (`playerProgressStore`), nunca códigos, tokens ou conteúdo do
perfil.

Limitação conhecida: o procedimento atual não faz `fsync` do diretório após o
rename. Isso reduz a janela de falha, mas não substitui snapshot/backup do
volume nem uma solução de banco transacional.

## Requisitos obrigatórios antes de produção

O valor atual de `ONLINE_RELAY_BASE_URL` é HTTP. Por decisão de segurança o
cliente **bloqueia** create/claim/sync de progresso enquanto a URL não começar
com `https://`. Não trocar esse bloqueio por exceção temporária.

Checklist de deploy:

- [ ] Terminar TLS em domínio/certificado válido e mudar a URL de progresso
      para HTTPS; confirmar create, claim e sync no aparelho real.
- [ ] Configurar `PLAYER_PROGRESS_PATH` em volume persistente fora do diretório
      de deploy e com permissões restritas ao usuário do relay.
- [ ] Agendar backup cifrado e externo do primário e de seus snapshots; não
      confiar apenas no arquivo `.bak` local.
- [ ] Executar um restore em ambiente isolado e conferir contagem de
      identidades/snapshots antes do primeiro lançamento e periodicamente.
- [ ] Monitorar `/health.playerProgressStore`; investigar imediatamente
      `recovered_backup` e bloquear alterações em `protected_read_only`.
- [ ] Manter segredos de infraestrutura e chaves de assinatura fora de Git e
      fora de logs.

Nenhum volume, backup ou certificado da VPS foi inferido como existente nesta
alteração: a verificação exige acesso operacional explícito ao ambiente.

## Ameaças cobertas e limites

| Ameaça | Resposta atual | Limite restante |
| --- | --- | --- |
| APK/cache adulterado | assinatura local detecta alteração casual; servidor revalida cada evento | segredo local e token ainda não usam armazenamento seguro nativo no Android nesta base |
| replay/duplicação | `event_id` idempotente e sequência por dispositivo | eventos legados v1 continuam aceitos por compatibilidade |
| perfil por apelido/UUID | recuperação apenas por código aleatório | jogador que perdeu o código não pode ser recuperado automaticamente |
| enumeração/brute force | resposta genérica, código 128-bit, rate limit | rate limits não são compartilhados entre múltiplas instâncias |
| corrupção de arquivo | backup e modo somente leitura protegido | não substitui backup externo/restauração auditada |
| rede insegura | cliente recusa HTTP para esse fluxo | TLS ainda precisa ser instalado no relay |

## Validações automatizadas

- `server/player_progress_smoke.js`: criação, progresso canônico, replay,
  token adulterado, rejeição detalhada, ordem por dispositivo, fila offline,
  claim após “reinstalação”, backup válido e store duplamente corrompido em
  modo protegido.
- `tests/player_progress_cache_smoke.gd`: schemas de cache v1/v2, assinatura,
  adulteração, corrupção, fila e ausência de descarte silencioso.
- `tests/runtime_backup_reconciliation_smoke.gd`: perfil sem código salvo,
  cache, escolha explícita antes de criar identidade, fila cheia, snapshot
  remoto antigo, resume/retry e compatibilidade de backup.
- `tests/player_progress_profile_visual_smoke.gd`: telas desktop/mobile de
  recuperação e da confirmação de criação, com capturas PNG.

Ainda não foram executados contra uma VPS/Android físico: TLS, backup externo,
restauração real, múltiplos dispositivos com latência real e integração com
armazenamento seguro da plataforma. Esses itens permanecem pré-requisitos de
lançamento, não resultados assumidos.
