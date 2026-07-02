# -*- coding: utf-8 -*-
"""Passivas compartilhadas das aureas Nula, Abissal, Profetica e Sanguinaria."""

import math
import random


AUREAS_NOVAS = ("Nula", "Abissal", "Profetica", "Sanguinaria")


def _nivel(estados, nome):
    return max(1, int(estados.get(nome, {}).get("nivel", 0)))


def _ativa(estados, aurea, nome):
    return aurea == nome and nome in estados


def _centro_rect(alvo):
    rect = alvo.get("rect") if isinstance(alvo, dict) else None
    if rect is None:
        return 0, 0
    return rect.centerx, rect.centery


def _registrar_texto(efeitos_texto, texto, x, y, tempo, cor):
    if efeitos_texto is None:
        return
    try:
        import Variaveis
        Variaveis.registrar_efeito_texto(efeitos_texto, texto, int(x), int(y), tempo, cor)
    except Exception:
        pass


def criar_estado_novas_aureas(upgrades, agora_ms):
    return {
        "Nula": {
            "nivel": upgrades.get("Nula", 0),
            "vazio": 0.0,
            "ultimo_ms": agora_ms,
            "feedback_ate": 0,
        },
        "Abissal": {
            "nivel": upgrades.get("Abissal", 0),
            "colapso": 0.0,
            "ultimo_ms": agora_ms,
            "ultimo_pulso_ms": 0,
        },
        "Profetica": {
            "nivel": upgrades.get("Profetica", 0),
            "alvo_id": None,
            "marcado_ate": 0,
            "proximo_pressagio_ms": agora_ms + 2800,
            "feedback_ate": 0,
        },
        "Sanguinaria": {
            "nivel": upgrades.get("Sanguinaria", 0),
            "sede": 0.0,
            "ultimo_ms": agora_ms,
            "carnificina_ate": 0,
        },
    }


def marcar_disparo(estados, aurea, disparo, tempo_atual):
    if not isinstance(disparo, dict):
        return disparo

    if _ativa(estados, aurea, "Nula"):
        estado = estados["Nula"]
        if estado["vazio"] >= 100.0:
            disparo["aurea_nula_nulifica"] = True
            estado["vazio"] = 0.0
            estado["feedback_ate"] = tempo_atual + 700

    if _ativa(estados, aurea, "Sanguinaria"):
        disparo["aurea_sanguinaria"] = True

    if _ativa(estados, aurea, "Profetica"):
        disparo["aurea_profetica"] = True

    return disparo


def atualizar(estados, aurea, tempo_atual, pos_x, pos_y, largura, altura, inimigos, efeitos_texto, dano_base, fator_tempo=1.0):
    mortos = []
    centro_player = (pos_x + largura // 2, pos_y + altura // 2)
    dt_s = max(0.0, min(0.08, float(fator_tempo)))

    if _ativa(estados, aurea, "Nula"):
        estado = estados["Nula"]
        anterior = estado.get("ultimo_ms", tempo_atual)
        delta_s = max(0.0, min(0.2, (tempo_atual - anterior) / 1000.0))
        estado["ultimo_ms"] = tempo_atual
        ganho = 7.0 + _nivel(estados, "Nula") * 1.25
        if len(inimigos) <= 3:
            ganho *= 1.35
        estado["vazio"] = min(100.0, estado["vazio"] + ganho * delta_s)

    if _ativa(estados, aurea, "Abissal"):
        estado = estados["Abissal"]
        nivel = _nivel(estados, "Abissal")
        estado["colapso"] = min(100.0, estado["colapso"] + (2.2 + min(12, len(inimigos)) * 0.42) * dt_s)
        raio = 155 + nivel * 14
        dano_erosao = max(0.0, dano_base * (0.006 + nivel * 0.0015) * dt_s)
        for inimigo in list(inimigos):
            if inimigo.get("invisivel", False) or "rect" not in inimigo:
                continue
            cx, cy = _centro_rect(inimigo)
            dx = centro_player[0] - cx
            dy = centro_player[1] - cy
            dist = math.hypot(dx, dy)
            if dist <= raio:
                inimigo["abissal_exposto_ate"] = tempo_atual + 220
                if dano_erosao > 0 and inimigo.get("vida", 1) > 1:
                    inimigo["vida"] = max(1, inimigo["vida"] - dano_erosao)
                if dist > 12:
                    puxao = (0.04 + nivel * 0.01) * fator_tempo
                    inimigo["rect"].x += int((dx / dist) * puxao)
                    inimigo["rect"].y += int((dy / dist) * puxao)
        if estado["colapso"] >= 100.0 and tempo_atual - estado.get("ultimo_pulso_ms", 0) >= 850:
            estado["colapso"] = 0.0
            estado["ultimo_pulso_ms"] = tempo_atual
            for inimigo in list(inimigos):
                if inimigo.get("invisivel", False) or "rect" not in inimigo:
                    continue
                cx, cy = _centro_rect(inimigo)
                if math.hypot(centro_player[0] - cx, centro_player[1] - cy) <= raio:
                    dano = max(1.0, dano_base * (0.18 + nivel * 0.035))
                    inimigo["vida"] -= dano
                    _registrar_texto(efeitos_texto, "COLAPSO", cx, cy - 28, tempo_atual, (105, 205, 255))
                    if inimigo.get("vida", 1) <= 0:
                        mortos.append(inimigo)

    if _ativa(estados, aurea, "Profetica"):
        estado = estados["Profetica"]
        if tempo_atual >= estado.get("marcado_ate", 0) and tempo_atual >= estado.get("proximo_pressagio_ms", 0):
            candidatos = [i for i in inimigos if not i.get("invisivel", False) and i.get("vida", 1) > 0 and "rect" in i]
            if candidatos:
                alvo = min(candidatos, key=lambda i: math.hypot(centro_player[0] - i["rect"].centerx, centro_player[1] - i["rect"].centery))
                duracao = 3100 + _nivel(estados, "Profetica") * 250
                alvo["profetica_marcado_ate"] = tempo_atual + duracao
                estado["alvo_id"] = id(alvo)
                estado["marcado_ate"] = tempo_atual + duracao
                estado["proximo_pressagio_ms"] = tempo_atual + 6200

    if _ativa(estados, aurea, "Sanguinaria"):
        estado = estados["Sanguinaria"]
        anterior = estado.get("ultimo_ms", tempo_atual)
        delta_s = max(0.0, min(0.2, (tempo_atual - anterior) / 1000.0))
        estado["ultimo_ms"] = tempo_atual
        estado["sede"] = max(0.0, estado["sede"] - (5.0 - min(2.0, _nivel(estados, "Sanguinaria") * 0.25)) * delta_s)
        for inimigo in inimigos:
            if inimigo.get("sanguinaria_ferida_ate", 0) > tempo_atual:
                inimigo["sanguinaria_aberto"] = True
            else:
                inimigo.pop("sanguinaria_aberto", None)

    return mortos


def aplicar_dano_em_alvo(estados, aurea, tempo_atual, alvo, dano, disparo=None, efeitos_texto=None, inimigos=None):
    if not isinstance(alvo, dict):
        return dano
    cx, cy = _centro_rect(alvo)

    if _ativa(estados, aurea, "Nula") and isinstance(disparo, dict) and disparo.get("aurea_nula_nulifica"):
        nivel = _nivel(estados, "Nula")
        dano *= 1.14 + nivel * 0.018
        alvo["nulificado_ate"] = tempo_atual + 2200 + nivel * 180
        _registrar_texto(efeitos_texto, "NULO", cx, cy - 34, tempo_atual, (225, 245, 255))

    if _ativa(estados, aurea, "Abissal") and alvo.get("abissal_exposto_ate", 0) > tempo_atual:
        dano *= 1.06 + _nivel(estados, "Abissal") * 0.012

    if _ativa(estados, aurea, "Profetica") and alvo.get("profetica_marcado_ate", 0) > tempo_atual:
        nivel = _nivel(estados, "Profetica")
        dano *= 1.18 + nivel * 0.028
        alvo["profetica_marcado_ate"] = 0
        estado = estados["Profetica"]
        estado["marcado_ate"] = 0
        estado["proximo_pressagio_ms"] = tempo_atual + max(2600, 5300 - nivel * 250)
        estado["feedback_ate"] = tempo_atual + 850
        _registrar_texto(efeitos_texto, "PRESSAGIO", cx, cy - 34, tempo_atual, (255, 230, 105))

    if _ativa(estados, aurea, "Sanguinaria"):
        nivel = _nivel(estados, "Sanguinaria")
        alvo["sanguinaria_hits"] = alvo.get("sanguinaria_hits", 0) + 1
        if alvo["sanguinaria_hits"] >= 2:
            alvo["sanguinaria_ferida_ate"] = tempo_atual + 3800 + nivel * 300
            dano *= 1.07 + nivel * 0.018
            estado = estados["Sanguinaria"]
            estado["sede"] = min(100.0, estado["sede"] + 10.0 + nivel * 2.5)
            if estado["sede"] >= 100.0:
                estado["sede"] = 38.0
                estado["carnificina_ate"] = tempo_atual + 2600 + nivel * 220
                _registrar_texto(efeitos_texto, "CARNIFICINA", cx, cy - 42, tempo_atual, (255, 75, 95))
        if estados["Sanguinaria"].get("carnificina_ate", 0) > tempo_atual:
            dano *= 1.12 + nivel * 0.015

    return dano


def aplicar_dano_boss(estados, aurea, tempo_atual, dano, disparo=None, efeitos_texto=None, pos_texto=None):
    alvo = {"vida": 1, "rect": None}
    if _ativa(estados, aurea, "Profetica"):
        estado = estados["Profetica"]
        if tempo_atual >= estado.get("proximo_pressagio_ms", 0):
            estado["proximo_pressagio_ms"] = tempo_atual + max(2800, 5600 - _nivel(estados, "Profetica") * 250)
            estado["feedback_ate"] = tempo_atual + 900
            dano *= 1.16 + _nivel(estados, "Profetica") * 0.025
            if pos_texto:
                _registrar_texto(efeitos_texto, "PRESSAGIO", pos_texto[0], pos_texto[1], tempo_atual, (255, 230, 105))
    if _ativa(estados, aurea, "Nula") and isinstance(disparo, dict) and disparo.get("aurea_nula_nulifica"):
        dano *= 1.10 + _nivel(estados, "Nula") * 0.015
        if pos_texto:
            _registrar_texto(efeitos_texto, "NULO", pos_texto[0], pos_texto[1] - 8, tempo_atual, (225, 245, 255))
    if _ativa(estados, aurea, "Sanguinaria"):
        nivel = _nivel(estados, "Sanguinaria")
        estado = estados["Sanguinaria"]
        estado["boss_hits"] = estado.get("boss_hits", 0) + 1
        if estado["boss_hits"] >= 2:
            dano *= 1.06 + nivel * 0.014
            estado["sede"] = min(100.0, estado.get("sede", 0.0) + 7.0 + nivel * 1.5)
            if estado["sede"] >= 100.0:
                estado["sede"] = 38.0
                estado["carnificina_ate"] = tempo_atual + 2400 + nivel * 200
                if pos_texto:
                    _registrar_texto(efeitos_texto, "CARNIFICINA", pos_texto[0], pos_texto[1] - 8, tempo_atual, (255, 75, 95))
        if estado.get("carnificina_ate", 0) > tempo_atual:
            dano *= 1.10 + nivel * 0.012
    return dano


def desenhar(tela, estados, aurea, tempo_atual, largura_tela, config_graficos, player_pos=None):
    if aurea not in AUREAS_NOVAS or not config_graficos.get("interface", True):
        return
    try:
        import pygame
    except Exception:
        return

    dados = {
        "Nula": ("VAZIO", estados["Nula"].get("vazio", 0.0), (215, 240, 255)),
        "Abissal": ("COLAPSO", estados["Abissal"].get("colapso", 0.0), (80, 180, 255)),
        "Profetica": ("PRESSAGIO", 100.0 if estados["Profetica"].get("feedback_ate", 0) > tempo_atual else 0.0, (255, 225, 85)),
        "Sanguinaria": ("SEDE", estados["Sanguinaria"].get("sede", 0.0), (255, 70, 92)),
    }
    titulo, valor, cor = dados[aurea]
    x = int(largura_tela // 2 - 108)
    y = 78
    w = 216
    h = 12
    pygame.draw.rect(tela, (8, 8, 16), (x - 2, y - 2, w + 4, h + 24), border_radius=6)
    pygame.draw.rect(tela, (36, 38, 48), (x, y, w, h), border_radius=5)
    pygame.draw.rect(tela, cor, (x, y, int(w * max(0.0, min(1.0, valor / 100.0))), h), border_radius=5)
    pygame.draw.rect(tela, (235, 235, 245), (x, y, w, h), 1, border_radius=5)
    fonte = pygame.font.Font(None, 18)
    texto = fonte.render(titulo, True, cor)
    tela.blit(texto, (x, y + 15))
