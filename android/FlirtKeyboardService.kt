package com.example.flirtkeyboard

import android.content.ClipboardManager
import android.content.Context
import android.inputmethodservice.InputMethodService
import android.view.LayoutInflater
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.Toast
import androidx.core.view.isVisible
import com.google.android.material.chip.ChipGroup
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException

/**
 * FlirtKeyboardService - Teclado customizado para sugestões de respostas com IA
 *
 * Este serviço estende InputMethodService para criar um teclado customizado que:
 * 1. Captura texto da área de transferência
 * 2. Envia para API de análise (backend Node.js)
 * 3. Insere sugestões de resposta diretamente no campo de texto
 *
 * PERMISSÕES NECESSÁRIAS:
 * - INTERNET (para chamadas HTTP)
 * - READ_CLIPBOARD (implícito ao usar ClipboardManager)
 *
 * CONFIGURAÇÃO:
 * - Veja AndroidManifest.xml para configuração completa
 */
class FlirtKeyboardService : InputMethodService(), CoroutineScope by MainScope() {

    // MARK: - Properties

    private var keyboardView: View? = null
    private var suggestButton: Button? = null
    private var toneChipGroup: ChipGroup? = null

    private val client = OkHttpClient()
    private val apiBaseUrl = "http://10.0.2.2:3000" // 10.0.2.2 é o localhost do emulador

    // Tons disponíveis
    private val toneMap = mapOf(
        R.id.chip_engracado to "engraçado",
        R.id.chip_ousado to "ousado",
        R.id.chip_romantico to "romântico",
        R.id.chip_casual to "casual",
        R.id.chip_confiante to "confiante"
    )

    private var selectedTone: String = "casual"

    // MARK: - Lifecycle Methods

    /**
     * Chamado quando a view do teclado é criada
     * Aqui inflamos o layout XML customizado
     */
    override fun onCreateInputView(): View {
        // Inflar o layout XML do teclado
        keyboardView = LayoutInflater.from(this).inflate(R.layout.keyboard_layout, null)

        setupViews()
        setupListeners()

        return keyboardView!!
    }

    /**
     * Chamado quando o serviço é destruído
     * Importante: Cancelar coroutines para evitar memory leaks
     */
    override fun onDestroy() {
        super.onDestroy()
        cancel() // Cancela todas as coroutines ativas
    }

    // MARK: - View Setup

    private fun setupViews() {
        keyboardView?.let { view ->
            suggestButton = view.findViewById(R.id.btn_suggest)
            toneChipGroup = view.findViewById(R.id.chip_group_tones)
        }
    }

    private fun setupListeners() {
        // Listener do botão de sugestão
        suggestButton?.setOnClickListener {
            onSuggestButtonClicked()
        }

        // Listener dos chips de tom
        toneChipGroup?.setOnCheckedStateChangeListener { group, checkedIds ->
            if (checkedIds.isNotEmpty()) {
                selectedTone = toneMap[checkedIds.first()] ?: "casual"
            }
        }
    }

    // MARK: - Clipboard Functions

    /**
     * Captura o texto da área de transferência (clipboard)
     *
     * IMPORTANTE: A partir do Android 10 (API 29), acessar o clipboard
     * em background mostra um toast automático ao usuário por questões de privacidade
     *
     * @return String com o texto copiado ou null se não houver
     */
    private fun getClipboardText(): String? {
        val clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

        // Verificar se há dados no clipboard
        if (!clipboardManager.hasPrimaryClip()) {
            showToast("Nenhum texto copiado encontrado. Copie uma mensagem primeiro!")
            return null
        }

        // Obter o texto
        val clipData = clipboardManager.primaryClip
        val item = clipData?.getItemAt(0)
        val text = item?.text?.toString()

        // Validar texto
        if (text.isNullOrBlank()) {
            showToast("Texto da área de transferência está vazio")
            return null
        }

        return text
    }

    // MARK: - Network Functions

    /**
     * Faz requisição HTTP para o backend usando OkHttp
     * Usa coroutines para operação assíncrona sem bloquear a UI
     *
     * @param text Texto a ser analisado
     * @param tone Tom da resposta (engraçado, ousado, etc)
     * @param onSuccess Callback com a resposta da API
     * @param onError Callback com mensagem de erro
     */
    private fun analyzeText(
        text: String,
        tone: String,
        onSuccess: (String) -> Unit,
        onError: (String) -> Unit
    ) {
        // Criar JSON do body
        val jsonBody = JSONObject().apply {
            put("text", text)
            put("tone", tone)
        }

        // Criar RequestBody
        val mediaType = "application/json; charset=utf-8".toMediaType()
        val requestBody = jsonBody.toString().toRequestBody(mediaType)

        // Criar Request
        val request = Request.Builder()
            .url("$apiBaseUrl/analyze")
            .post(requestBody)
            .build()

        // Fazer chamada assíncrona usando coroutines
        launch(Dispatchers.IO) {
            try {
                val response = client.newCall(request).execute()

                if (!response.isSuccessful) {
                    withContext(Dispatchers.Main) {
                        onError("Erro no servidor: ${response.code}")
                    }
                    return@launch
                }

                // Parse JSON da resposta
                val responseBody = response.body?.string()
                val jsonResponse = JSONObject(responseBody ?: "{}")
                val analysis = jsonResponse.optString("analysis", "")

                if (analysis.isBlank()) {
                    withContext(Dispatchers.Main) {
                        onError("Resposta vazia do servidor")
                    }
                    return@launch
                }

                // Retornar sucesso na Main thread
                withContext(Dispatchers.Main) {
                    onSuccess(analysis)
                }

            } catch (e: IOException) {
                withContext(Dispatchers.Main) {
                    onError("Erro de rede: ${e.message}")
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    onError("Erro: ${e.message}")
                }
            }
        }
    }

    // MARK: - Text Insertion Functions

    /**
     * Insere texto no campo de entrada usando InputConnection
     *
     * currentInputConnection é a API oficial do Android para teclados customizados
     * manipularem o campo de texto ativo. Funciona em qualquer app.
     *
     * @param text Texto a ser inserido
     */
    private fun insertText(text: String) {
        val inputConnection = currentInputConnection ?: run {
            showToast("Erro: Conexão com campo de texto perdida")
            return
        }

        // commitText é o método correto para inserir texto
        // Parâmetros:
        // 1. CharSequence: texto a inserir
        // 2. Int: nova posição do cursor (1 = após o texto inserido)
        inputConnection.commitText(text, 1)
    }

    /**
     * Deleta todo o texto antes do cursor
     * Útil para substituir texto existente
     */
    private fun deleteAllText() {
        val inputConnection = currentInputConnection ?: return

        // Obter texto antes do cursor
        val textBeforeCursor = inputConnection.getTextBeforeCursor(1000, 0)
        val length = textBeforeCursor?.length ?: 0

        if (length > 0) {
            // Deletar caracteres
            inputConnection.deleteSurroundingText(length, 0)
        }
    }

    /**
     * Obtém o texto atual do campo de entrada
     * Útil para análise de contexto
     */
    private fun getCurrentText(): String? {
        val inputConnection = currentInputConnection ?: return null

        val textBefore = inputConnection.getTextBeforeCursor(1000, 0)
        val textAfter = inputConnection.getTextAfterCursor(1000, 0)

        return "$textBefore$textAfter"
    }

    // MARK: - Button Actions

    private fun onSuggestButtonClicked() {
        // Capturar texto do clipboard
        val clipboardText = getClipboardText() ?: return

        // Mostrar feedback visual
        setButtonLoading(true)

        // Fazer análise
        analyzeText(
            text = clipboardText,
            tone = selectedTone,
            onSuccess = { suggestion ->
                // Inserir sugestão no campo de texto
                insertText(suggestion)

                // Restaurar botão
                setButtonLoading(false)

                // Feedback ao usuário
                showToast("Sugestão inserida! 🎉")
            },
            onError = { errorMessage ->
                // Restaurar botão
                setButtonLoading(false)

                // Mostrar erro
                showToast(errorMessage)
            }
        )
    }

    // MARK: - Helper Functions

    /**
     * Alterna estado de loading do botão
     */
    private fun setButtonLoading(isLoading: Boolean) {
        suggestButton?.apply {
            this.isEnabled = !isLoading
            text = if (isLoading) "🔄 Analisando..." else "✨ Sugerir Resposta"
        }
    }

    /**
     * Mostra um Toast para feedback ao usuário
     */
    private fun showToast(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
    }

    // MARK: - InputMethodService Overrides

    /**
     * Chamado quando o campo de texto muda de foco
     * Útil para adaptar o teclado baseado no tipo de campo (email, senha, etc)
     */
    override fun onStartInput(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInput(attribute, restarting)

        // Você pode adaptar o teclado baseado no inputType
        // Por exemplo, ocultar o botão de sugestão em campos de senha
        when (attribute?.inputType?.and(EditorInfo.TYPE_MASK_CLASS)) {
            EditorInfo.TYPE_CLASS_TEXT -> {
                // Campo de texto normal - mostrar teclado completo
                suggestButton?.isVisible = true
            }
            EditorInfo.TYPE_TEXT_VARIATION_PASSWORD -> {
                // Campo de senha - ocultar sugestões por privacidade
                suggestButton?.isVisible = false
            }
        }
    }
}

/*
 * NOTAS DE DESENVOLVIMENTO:
 *
 * 1. LOCALHOST vs EMULADOR vs DISPOSITIVO FÍSICO:
 *    - Emulador Android: use "10.0.2.2:3000" (mapeia para localhost da máquina host)
 *    - Dispositivo físico: use o IP da sua máquina na rede local (ex: "192.168.1.100:3000")
 *    - Para produção: substitua por sua URL de produção
 *
 * 2. PERMISSÕES DE REDE:
 *    - Android requer permissão INTERNET no AndroidManifest.xml
 *    - HTTP cleartext (não-HTTPS) requer configuração adicional de segurança
 *
 * 3. CLIPBOARD NO ANDROID 10+:
 *    - Android mostra um toast automático quando apps acessam o clipboard em background
 *    - Isso é por design para privacidade do usuário
 *
 * 4. COROUTINES:
 *    - Usadas para operações assíncronas sem bloquear a UI
 *    - Importante cancelar no onDestroy() para evitar memory leaks
 *
 * 5. INPUT CONNECTION:
 *    - currentInputConnection pode ser null se não houver campo de texto ativo
 *    - Sempre verificar null antes de usar
 */
