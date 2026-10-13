# Registry de definições de Evolução

O catálogo agora trata o ID serializado da evolução como sua chave canônica.
Cada definição retornada por `RTManifestEvolutionCatalog.definition_by_id(id)`
inclui `definition_id`, `definition_schema_version`, `trigger`, `conditions`,
`state_key`, `state_policy`, `visual_tag`, `test_target` e o `profile` que o
runtime já consome.

## Contrato para os próximos reworks

- Mantenha o ID, o estágio (`ev1`/`ev2`) e a escolha de três opções; são
  contratos de UI, save e rede.
- Troque apenas a definição daquele ID. Reutilizar primitivas de combate é
  permitido, mas o `trigger`, as condições e o estado devem descrever a regra
  própria da evolução.
- Estado persistente novo pertence a `manifest_evolution_state` e deve ser
  namespaced pelo `state_key` da definição. Estado transitório de evento não é
  salvo.
- O VFX lê `visual_tag` e a identidade da definição; ele não é evidência de
  efeito mecânico. Cada rework precisa atualizar o smoke apontado por
  `test_target` com uma consequência mensurável.
- `normalize_saved_choice` preserva o `profile` de saves antigos e apenas
  anexa metadados. IDs removidos/desconhecidos recebem `unknown_legacy` e não
  podem causar crash.

## Limite desta fase

Esta fase converte os 180 IDs para o registry sem mudar os perfis legados.
Ela remove a escolha de mecânica por posição da oferta. A diversidade real
das 15 manifestações continua pendente e será entregue por reworks individuais;
o registry não transforma um efeito legado genérico em mecânica exclusiva.
