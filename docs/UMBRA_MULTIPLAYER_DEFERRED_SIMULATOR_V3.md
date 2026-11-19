# Pendência de registro — simulador/percepção v3

Data: 16/11/2026. O ambiente rejeitou automaticamente a gravação em
`.agents/MULTIPLAYER_DEFERRED_VALIDATION.md` por proteção de caminho. Esta
anotação preserva o conteúdo que deveria ser acrescentado lá, sem alterar
o backlog existente.

- Cena/adaptador de pesquisa executam o combate herdado a 60 Hz, com
  cadência normal e comandos de alvo/espaço solo. Observação/modelo v3
  exigem opt-in; o padrão v2 permanece 83 entradas/23 ações e rejeita os
  artefatos de pesquisa. O builder v3 rejeita runtime multiplayer.
- Evidência solo: `tests/umbra_training_environment_smoke.gd` cobre aceitação
  v2, inferência v3 explícita, dimensões, mapa ampliado, categorias de ameaça,
  ameaça desconhecida, dano atrasado, movimento/dano de projéteis, cadência,
  ação ilegal e efeito espacial. Os smokes Python verificam replay completo,
  dano nos dois sentidos, limites de recompensa e truncamento.
- Quando a validação multiplayer for retomada: regressão host/client do
  caminho v2 de inferência/autoridade/snapshot; recusa de carregamento
  automático v3 em produção/sessão remota. Uma extensão multiplayer do v3
  ainda deve validar posições/velocidades/vida remotas, escala do mapa,
  máscaras/seleção de alvo, execução espacial, morte/revive e não execução
  em réplicas.
- Nenhum servidor dedicado, host/client, relay, lobby, sessão online ou
  teste físico em múltiplos dispositivos foi executado nesta etapa.
