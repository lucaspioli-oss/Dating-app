package com.desenrolaai.app.keyboard.data

data class Objective(
    val id: String,
    val emoji: String,
    val title: String,
    val description: String
)

val availableObjectives = listOf(
    Objective("automatico", "\uD83C\uDFAF", "Automático", "IA escolhe com base no contexto"),
    Objective("pegar_numero", "\uD83D\uDCF1", "Pegar Número", "Pedir o número dela naturalmente"),
    Objective("marcar_encontro", "☕", "Marcar Encontro", "Convite confiante para sair"),
    Objective("modo_intimo", "\uD83D\uDD25", "Modo Íntimo", "Mensagens sedutoras"),
    Objective("mudar_plataforma", "\uD83D\uDCAC", "Mudar Plataforma", "Migrar para outro app"),
    Objective("reacender", "\uD83D\uDD04", "Reacender", "Retomar conversa parada"),
    Objective("virar_romantico", "\uD83D\uDC95", "Virar Romântico", "De amigável para flerte"),
    Objective("video_call", "\uD83C\uDFA5", "Video Call", "Conduzir para vídeo chamada"),
    Objective("pedir_desculpas", "\uD83D\uDE4F", "Desculpas", "Pedido genuíno de desculpas"),
    Objective("criar_conexao", "\uD83E\uDD1D", "Criar Conexão", "Aprofundar conexão emocional"),
)
