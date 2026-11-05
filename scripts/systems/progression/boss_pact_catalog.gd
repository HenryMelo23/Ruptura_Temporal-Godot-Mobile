class_name RTBossPactCatalog
extends RefCounted

## Pactos pos-batalha: depois dos chefes 1, 3, 4, 5 e 6 o jogador escolhe 1 de 3
## (obrigatorio, sem rerrolar). Todo pacto tem um ganho forte e uma marca caotica
## com explicacao historica do que a batalha fez com a personagem. {hero} vira o
## nome da personagem ativa.
##
## Chaves de efeito (multiplicam/somam; varios pactos se acumulam):
##   dmg, boss_dmg, atk (intervalo do ATK: < 1 = mais rapido), move, dash_cd,
##   pickup, points, heal, dmg_taken -> multiplicadores
##   crit, defense, lifesteal, luck -> soma unica ao escolher
##   max_hp, enemy_hp, enemy_speed, enemy_dmg -> multiplicador unico ao escolher
## Mecanicas (RTBossPactController): lightning, darkness, stillness, drain,
##   heal_still, blink, meteors, death_burst, gust, tremor.

const PACTS: Array[Dictionary] = [
	{"id": "perna_ferida", "name": "Perna Ferida", "buff": "+12% chance de critico", "debuff": "-12% velocidade de movimento",
		"lore": "Na queda do chefe, {hero} torceu a perna. Cada passo doi, mas a dor afiou a mira.", "fx": {"crit": 0.12, "move": 0.88}},
	{"id": "eletrons_alterados", "name": "Eletrons Alterados", "buff": "+18% velocidade de movimento", "debuff": "Raios caem perto de voce a cada 7 s",
		"lore": "A energia exalada por {hero} alterou os eletrons do espaco, que agora atraem raios.", "fx": {"move": 1.18}, "mech": {"lightning": 7.0}},
	{"id": "olhos_queimados", "name": "Olhos Queimados", "buff": "+22% de dano", "debuff": "Campo de visao reduzido",
		"lore": "O clarao do golpe final machucou os olhos de {hero}. O mundo escureceu, a raiva nao.", "fx": {"dmg": 1.22}, "mech": {"darkness": 340.0}},
	{"id": "coracao_acelerado", "name": "Coracao Acelerado", "buff": "Ataque 18% mais rapido", "debuff": "+15% de dano recebido",
		"lore": "A adrenalina da luta ficou presa no peito. {hero} nao consegue mais desacelerar.", "fx": {"atk": 0.85, "dmg_taken": 1.15}},
	{"id": "pele_de_vidro", "name": "Pele de Vidro", "buff": "+35% de dano", "debuff": "-25% de vida maxima",
		"lore": "O nucleo do chefe cristalizou a pele de {hero}: cada golpe e mais forte, cada arranhao, mais fundo.", "fx": {"dmg": 1.35, "max_hp": 0.75}},
	{"id": "sangue_fervente", "name": "Sangue Fervente", "buff": "+4% de roubo de vida", "debuff": "Sem abater por 3 s, voce perde vida",
		"lore": "O sangue de {hero} ferve desde a batalha. So a luta consegue esfria-lo.", "fx": {"lifesteal": 0.04}, "mech": {"drain": 0.005}},
	{"id": "raiz_temporal", "name": "Raiz Temporal", "buff": "+20% de vida maxima e +10 de defesa", "debuff": "-15% velocidade de movimento",
		"lore": "Raizes do tempo cresceram nos pes de {hero}. Ela aguenta tudo, mas custa a sair do lugar.", "fx": {"max_hp": 1.2, "defense": 10.0, "move": 0.85}},
	{"id": "fome_cronal", "name": "Fome Cronal", "buff": "+30% de pontos por abate", "debuff": "-40% de cura recebida",
		"lore": "O tempo devorado pelo chefe deixou uma fome em {hero}: tudo vira ponto, nada sacia.", "fx": {"points": 1.3, "heal": 0.6}},
	{"id": "ima_quebrado", "name": "Ima Quebrado", "buff": "+60% de raio de coleta", "debuff": "Inimigos 8% mais rapidos",
		"lore": "O magnetismo do chefe grudou em {hero}. Atrai recursos... e a horda tambem.", "fx": {"pickup": 1.6, "enemy_speed": 1.08}},
	{"id": "fenda_instavel", "name": "Fenda Instavel", "buff": "Teleporte recarrega 30% mais rapido", "debuff": "A cada 22 s voce e arremessada para perto",
		"lore": "Uma fenda ficou aberta dentro de {hero}. As vezes ela engole a propria dona.", "fx": {"dash_cd": 0.7}, "mech": {"blink": 22.0}},
	{"id": "chuva_estilhacos", "name": "Chuva de Estilhacos", "buff": "+10% de dano e +8% de critico", "debuff": "Estilhacos caem do ceu a cada 6 s",
		"lore": "O ceu da dimensao rachou com a morte do chefe e ainda despeja os cacos.", "fx": {"dmg": 1.1, "crit": 0.08}, "mech": {"meteors": 6.0}},
	{"id": "eco_do_chefe", "name": "Eco do Chefe", "buff": "+40% de dano contra chefes", "debuff": "Inimigos com +15% de vida",
		"lore": "{hero} carrega o eco do inimigo derrotado. Os proximos chefes sentem; a horda tambem fica mais teimosa.", "fx": {"boss_dmg": 1.4, "enemy_hp": 1.15}},
	{"id": "inquietude", "name": "Inquietude", "buff": "+28% de dano", "debuff": "Ficar parada queima sua vida",
		"lore": "Desde a batalha {hero} nao consegue ficar quieta. Parar e sentir o tempo queimando por dentro.", "fx": {"dmg": 1.28}, "mech": {"stillness": 0.02}},
	{"id": "calmaria", "name": "Calmaria", "buff": "+60% de cura e +6 de defesa", "debuff": "Ataque 12% mais lento",
		"lore": "Depois do caos, {hero} encontrou calma. O corpo cura melhor, mas as maos ficaram lentas.", "fx": {"heal": 1.6, "defense": 6.0, "atk": 1.12}},
	{"id": "cadaveres_instaveis", "name": "Cadaveres Instaveis", "buff": "+20% de pontos e ataque 8% mais rapido", "debuff": "Inimigos explodem ao morrer",
		"lore": "Os restos do chefe contaminaram a horda: quem morre perto de {hero} morre explodindo.", "fx": {"points": 1.2, "atk": 0.92}, "mech": {"death_burst": 0.25}},
	{"id": "vento_cortante", "name": "Vento Cortante", "buff": "+15% de movimento e teleporte 15% mais rapido", "debuff": "Rajadas empurram voce a cada 9 s",
		"lore": "A tempestade da batalha seguiu {hero}. Ela corre com o vento, mas o vento nao pede licenca.", "fx": {"move": 1.15, "dash_cd": 0.85}, "mech": {"gust": 9.0}},
	{"id": "sorte_maldita", "name": "Sorte Maldita", "buff": "+8% de sorte", "debuff": "+20% de dano recebido",
		"lore": "O destino do chefe passou para {hero}. A sorte vem junto com o azar de quem o carregava.", "fx": {"luck": 0.08, "dmg_taken": 1.2}},
	{"id": "tremor_residual", "name": "Tremor Residual", "buff": "+18% de dano e +5% de critico", "debuff": "Tremores te deixam lenta por instantes",
		"lore": "O chao ainda treme onde o chefe caiu, e o tremor mora nas pernas de {hero}.", "fx": {"dmg": 1.18, "crit": 0.05}, "mech": {"tremor": 12.0}},
	{"id": "pulso_lento", "name": "Pulso Lento", "buff": "+30% de vida maxima e +2% de roubo de vida", "debuff": "-8% de movimento e ataque 8% mais lento",
		"lore": "O coracao de {hero} passou a bater no ritmo do tempo congelado. Forte, porem lento.", "fx": {"max_hp": 1.3, "lifesteal": 0.02, "move": 0.92, "atk": 1.08}},
	{"id": "visao_tunel", "name": "Visao de Tunel", "buff": "+18% de chance de critico", "debuff": "Campo de visao reduzido",
		"lore": "Para sobreviver, {hero} aprendeu a enxergar so o alvo. O resto do mundo virou borrao.", "fx": {"crit": 0.18}, "mech": {"darkness": 380.0}},
	{"id": "corpo_febril", "name": "Corpo Febril", "buff": "Ataque 25% mais rapido", "debuff": "So cura quando esta parada",
		"lore": "A febre da batalha acelera cada gesto de {hero}, mas o corpo so se recupera em repouso.", "fx": {"atk": 0.75}, "mech": {"heal_still": 1.0}},
	{"id": "cicatriz_viva", "name": "Cicatriz Viva", "buff": "+5% de roubo de vida", "debuff": "-15% de vida maxima",
		"lore": "A ferida aberta pelo chefe nunca fechou. Ela bebe dos inimigos para manter {hero} de pe.", "fx": {"lifesteal": 0.05, "max_hp": 0.85}},
	{"id": "ritmo_frenetico", "name": "Ritmo Frenetico", "buff": "+20% de movimento e ataque 10% mais rapido", "debuff": "+25% de dano recebido",
		"lore": "{hero} saiu da batalha acelerada demais para se proteger direito.", "fx": {"move": 1.2, "atk": 0.9, "dmg_taken": 1.25}},
	{"id": "couraca_rachada", "name": "Couraca Rachada", "buff": "+14 de defesa", "debuff": "-12% de dano",
		"lore": "Uma casca do chefe se fundiu as costas de {hero}. Protege muito, mas pesa em cada golpe.", "fx": {"defense": 14.0, "dmg": 0.88}},
	{"id": "para_raios", "name": "Para-raios", "buff": "Ataque 12% mais rapido e +6% de critico", "debuff": "Raios caem perto de voce a cada 5 s",
		"lore": "{hero} absorveu a carga do chefe e virou um para-raios vivo. Os raios te procuram.", "fx": {"atk": 0.88, "crit": 0.06}, "mech": {"lightning": 5.0}},
	{"id": "nevoa_interior", "name": "Nevoa Interior", "buff": "+35% de pontos e +4% de sorte", "debuff": "Campo de visao bem reduzido",
		"lore": "A nevoa da dimensao entrou nos olhos de {hero}. Ela enxerga pouco, mas enxerga o que vale ouro.", "fx": {"points": 1.35, "luck": 0.04}, "mech": {"darkness": 300.0}},
	{"id": "gravidade_pesada", "name": "Gravidade Pesada", "buff": "+25% de vida maxima e +8 de defesa", "debuff": "Teleporte recarrega 40% mais devagar",
		"lore": "A massa do chefe ficou presa em {hero}. Dificil de derrubar, dificil de levantar voo.", "fx": {"max_hp": 1.25, "defense": 8.0, "dash_cd": 1.4}},
	{"id": "ganancia", "name": "Ganancia", "buff": "+50% de pontos por abate", "debuff": "Inimigos com +20% de vida",
		"lore": "O tesouro do chefe falou com {hero}. Agora cada inimigo vale mais... e resiste mais.", "fx": {"points": 1.5, "enemy_hp": 1.2}},
	{"id": "furia_contida", "name": "Furia Contida", "buff": "+40% de dano", "debuff": "Ataque 15% mais lento",
		"lore": "{hero} guardou a furia do combate em cada golpe. Golpes pesados, mas que custam a sair.", "fx": {"dmg": 1.4, "atk": 1.15}},
	{"id": "passos_leves", "name": "Passos Leves", "buff": "+25% de movimento e +30% de coleta", "debuff": "-18% de vida maxima",
		"lore": "O chefe arrancou um pouco do peso de {hero}: leve como pluma, fragil como pluma.", "fx": {"move": 1.25, "pickup": 1.3, "max_hp": 0.82}},
	{"id": "instinto", "name": "Instinto", "buff": "+15% de critico e +2% de roubo de vida", "debuff": "Ficar parada queima sua vida",
		"lore": "A luta despertou um instinto de predadora em {hero}. Predadoras nao param.", "fx": {"crit": 0.15, "lifesteal": 0.02}, "mech": {"stillness": 0.018}},
	{"id": "maldicao_mercador", "name": "Maldicao do Mercador", "buff": "+10% de sorte e +15% de pontos", "debuff": "-50% de cura recebida",
		"lore": "O Mercador cobrou pela vitoria de {hero}: a sorte veio, a saude ficou de garantia.", "fx": {"luck": 0.1, "points": 1.15, "heal": 0.5}},
	{"id": "sangue_frio", "name": "Sangue Frio", "buff": "-18% de dano recebido", "debuff": "-10% de movimento e teleporte 25% mais lento",
		"lore": "O frio do chefe correu nas veias de {hero}. Nada a abala, mas tudo fica mais lento.", "fx": {"dmg_taken": 0.82, "move": 0.9, "dash_cd": 1.25}},
	{"id": "horda_atraida", "name": "Horda Atraida", "buff": "+40% de pontos e ataque 10% mais rapido", "debuff": "Inimigos 12% mais rapidos e 10% mais fortes",
		"lore": "O cheiro da vitoria de {hero} se espalhou pela dimensao. A horda quer vinganca.", "fx": {"points": 1.4, "atk": 0.9, "enemy_speed": 1.12, "enemy_dmg": 1.1}},
	{"id": "deriva_temporal", "name": "Deriva Temporal", "buff": "Teleporte 40% mais rapido e +10% de movimento", "debuff": "A cada 16 s voce e arremessada para perto",
		"lore": "{hero} ficou solta no tempo. Ela se move como quer... e as vezes como o tempo quer.", "fx": {"dash_cd": 0.6, "move": 1.1}, "mech": {"blink": 16.0}},
]


static func count() -> int:
	return PACTS.size()


static func by_id(id: String) -> Dictionary:
	for pact in PACTS:
		if String(pact["id"]) == id:
			return pact
	return {}


static func lore_for(pact: Dictionary, hero: String) -> String:
	return String(pact.get("lore", "")).replace("{hero}", hero)
