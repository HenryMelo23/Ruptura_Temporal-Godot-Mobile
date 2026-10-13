# Evoluções — defeitos expostos por fluxo público

Este registro é produzido pela suíte
`tests/manifest_evolution_public_contract_smoke.gd`. Ela seleciona a evolução
com `_choose_manifest_evolution`, usa os endpoints públicos de ataque, Q, E e
teleporte e avança as rotinas normais de combate. Ela não chama callbacks de
evolução diretamente.

## Como reproduzir

```sh
godot --headless --path . --script res://tests/manifest_evolution_public_contract_smoke.gd
```

O teste encerra com erro enquanto existir um contrato placebo. Cada linha usa
o identificador estável `EVP-<id>` para que o defeito possa ser rastreado sem
renomear save IDs.

## Falhas confirmadas no HEAD `dff2fac`

| Defeito | IDs afetados | Evidência comportamental | Escopo seguro de correção |
| --- | --- | --- | --- |
| `EVP-LACERANTE-PROJECTILE` | `lacerante_ev1_hemorragia_crescente`, `lacerante_ev1_cicatriz_aberta`, `lacerante_ev1_predador_rubro`, `lacerante_ev2_cicatriz_persistente`, `lacerante_ev2_execucao_cadeia` | O ataque público é corpo a corpo; não cria projétil e, por isso, eco, perfuração, mira e híbrido nunca podem executar. | Criar contratos próprios de golpe para esses cinco IDs, ou restringir o catálogo a efeitos compatíveis com Lacerante. |
| `EVP-ACORRENTADA-PROJECTILE` | `acorrentada_ev1_corrente_tripla`, `acorrentada_ev1_tensao_residual`, `acorrentada_ev1_grilhao_movel`, `acorrentada_ev2_prisao_total`, `acorrentada_ev2_sentenca_ferro` | A fonte real é a máquina de estados de corrente; não há projétil sobre o qual as cinco regras possam atuar. | Usar o evento de corrente/impacto já emitido, com limite por ataque, ou definir contratos próprios de cadeia. |
| `EVP-ACORRENTADA-SEAL` | `acorrentada_ev1_sobretensao_continua` | O resolvedor passa uma referência de alvo sem o campo de stun; o selo registra impacto, mas não altera o inimigo real. | Resolver o alvo autoritativo por `uid` antes de aplicar o selo. |
| `EVP-PRISMATICA-REFLECTION` | `prismatica_ev1_reflexao_dupla`, `prismatica_ev2_luz_recursiva` | Após o primeiro acerto, o ricochete normal da Prismática sobrescreve a direção escolhida pelo controlador; o terceiro alvo não recebe dano. | Definir a precedência entre ricochete base e reflexão evoluída; manter apenas uma mudança de direção por hit. |
| `EVP-RESSONANTE-SEAL-OVERLAP` | `ressonante_ev1_sincope` | O ataque base já entrega stun de `0.8`; o selo evoluído de `0.72` não aumenta duração, dano, controle nem alcance percebido. | Elevar/empilhar o efeito de forma explícita ou substituir o contrato por consequência tática diferente. |

## Revisão de design, não defeito automático de infraestrutura

Há 12 grupos semânticos compartilhados, cada um aplicado a 14 manifestações
não-Prismáticas. Dentro de cada grupo o catálogo conserva a mesma rotina e só
altera coeficientes, assinatura e tag visual. Isso não quebra a primitiva
compartilhada por si só, mas deve passar por revisão de design: nomes e
tooltips prometem especializações diferentes enquanto a semântica é a mesma.

Os grupos são os seis efeitos EV1 e os seis efeitos EV2 informados pela saída
`MANIFEST_EVOLUTION_DESIGN_REVIEW` da suíte. Nenhum desses grupos é marcado
como placebo apenas por compartilhar infraestrutura; a reprovação só ocorre
quando o caminho público não gera um resultado jogável mensurável.
