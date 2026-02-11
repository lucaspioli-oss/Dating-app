package com.desenrolaai.app.keyboard.network

/**
 * Parses AI response text into a list of suggestion strings.
 * 3-tier parsing matching iOS KeyboardViewController.parseSuggestions():
 *   1. Numbered list regex (1. 2. 3.)
 *   2. Quoted text extraction
 *   3. Sentence splitting with header filtering
 */
object SuggestionParser {

    private val skipPatterns = listOf(
        "#", "⚠️", "🚩", "📊", "🔍", "💡",
        "ANÁLISE", "ANALISE", "RED FLAG", "REDFLAG",
        "GRAU DE INVESTIMENTO", "INVESTIMENTO",
        "RACIOCÍNIO", "RACIOCINÍO",
        "SUGEST", "RESPOSTA", "OPÇÃO", "OPCÃO",
        "---", "***", "===",
        "CONTEXTO", "OBSERV", "NOTA:",
        "DICA:", "TIP:", "OBS:"
    )

    fun parse(text: String): List<String> {
        // Tier 1: numbered items
        val numbered = parseNumbered(text)
        if (numbered.isNotEmpty()) return numbered.take(3)

        // Tier 2: quoted text
        val quoted = parseQuoted(text)
        if (quoted.isNotEmpty()) return quoted.take(3)

        // Tier 3: sentence splitting
        val sentences = parseSentences(text)
        if (sentences.isNotEmpty()) return sentences.take(3)

        return listOf("Erro ao processar sugestões. Tente novamente.")
    }

    private fun parseNumbered(text: String): List<String> {
        val regex = Regex("""^\d+[.):\s]+(.+)""", RegexOption.MULTILINE)
        return regex.findAll(text)
            .map { it.groupValues[1].trim() }
            .filter { line -> !shouldSkip(line) }
            .map { it.removeSurrounding("\"").removeSurrounding("'").removeSurrounding("\u201C", "\u201D") }
            .filter { it.length >= 3 }
            .toList()
    }

    private fun parseQuoted(text: String): List<String> {
        val regex = Regex(""""([^"]{5,})"""")
        return regex.findAll(text)
            .map { it.groupValues[1].trim() }
            .toList()
    }

    private fun parseSentences(text: String): List<String> {
        return text.split("\n")
            .map { it.trim() }
            .filter { it.length >= 3 }
            .filter { line -> !shouldSkip(line) }
            .filter { !it.startsWith("-") && !it.startsWith("*") }
    }

    private fun shouldSkip(line: String): Boolean {
        val upper = line.uppercase()
        return skipPatterns.any { upper.contains(it) }
    }
}
