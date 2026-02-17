package com.desenrolaai.app.keyboard.ui

import android.content.Context
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.*
import com.desenrolaai.app.keyboard.Theme
import com.desenrolaai.app.keyboard.data.ConversationContext
import com.desenrolaai.app.keyboard.ui.components.GradientButton
import com.desenrolaai.app.keyboard.ui.components.HeaderBar
import com.desenrolaai.app.keyboard.ui.components.ProfileAvatarView

class ProfileSelectorView(
    private val context: Context,
    private val container: FrameLayout,
    private val conversations: List<ConversationContext>,
    private val filteredConversations: List<ConversationContext>,
    private val searchText: String,
    private val isLoading: Boolean,
    private val error: String?,
    private val onProfileSelected: (ConversationContext) -> Unit,
    private val onQuickMode: () -> Unit,
    private val onSearchChanged: (String) -> Unit,
    private val onSwitchKeyboard: () -> Unit
) {
    private val density = context.resources.displayMetrics.density

    fun render() {
        val root = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        // Title + globe
        val header = HeaderBar.create(
            context, "Com quem você está falando?",
            showGlobe = true, onGlobe = onSwitchKeyboard
        )
        root.addView(header)

        // Search bar
        val searchContainer = FrameLayout(context).apply {
            val bg = GradientDrawable().apply {
                setColor(Theme.cardBg)
                cornerRadius = 8 * density
            }
            background = bg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, (26 * density).toInt()
            ).apply {
                setMargins((12 * density).toInt(), (4 * density).toInt(), (12 * density).toInt(), (4 * density).toInt())
            }
        }
        val searchLabel = TextView(context).apply {
            text = if (searchText.isEmpty()) "\uD83D\uDD0D Buscar..." else "\uD83D\uDD0D $searchText"
            setTextColor(if (searchText.isEmpty()) Theme.textSecondary else 0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            gravity = Gravity.CENTER_VERTICAL
            setPadding((8 * density).toInt(), 0, (8 * density).toInt(), 0)
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        searchContainer.addView(searchLabel)
        root.addView(searchContainer)

        // QWERTY keyboard
        val qwertyContainer = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins((4 * density).toInt(), (2 * density).toInt(), (4 * density).toInt(), (2 * density).toInt())
            }
        }

        val rows = listOf(
            "QWERTYUIOP",
            "ASDFGHJKL",
            "ZXCVBNM"
        )

        for (row in rows) {
            val rowLayout = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    (26 * density).toInt()
                )
            }

            for (c in row) {
                val btn = makeMiniKeyButton(c.toString()) {
                    onSearchChanged(searchText + c.lowercaseChar())
                }
                rowLayout.addView(btn)
            }

            // Add backspace and clear to last row
            if (row == "ZXCVBNM") {
                rowLayout.addView(makeMiniKeyButton("⌫") {
                    if (searchText.isNotEmpty()) onSearchChanged(searchText.dropLast(1))
                })
                rowLayout.addView(makeMiniKeyButton("✕") {
                    onSearchChanged("")
                })
            }

            qwertyContainer.addView(rowLayout)
        }

        root.addView(qwertyContainer)

        // Profile list or loading/error
        if (isLoading) {
            val loadingLabel = TextView(context).apply {
                text = "Carregando perfis..."
                setTextColor(Theme.textSecondary)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, (56 * density).toInt()
                )
            }
            root.addView(loadingLabel)
        } else if (error != null) {
            val errorLabel = TextView(context).apply {
                text = error
                setTextColor(Theme.errorText)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, (56 * density).toInt()
                )
            }
            root.addView(errorLabel)
        } else if (filteredConversations.isEmpty()) {
            val emptyLabel = TextView(context).apply {
                text = "Nenhum perfil encontrado"
                setTextColor(Theme.textSecondary)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, (56 * density).toInt()
                )
            }
            root.addView(emptyLabel)
        } else {
            val profileScroll = HorizontalScrollView(context).apply {
                isHorizontalScrollBarEnabled = false
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, (90 * density).toInt()
                ).apply {
                    setMargins((8 * density).toInt(), (2 * density).toInt(), (8 * density).toInt(), 0)
                }
            }
            val profileRow = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }

            for (conv in filteredConversations) {
                val avatar = ProfileAvatarView.create(
                    context, conv.matchName, conv.faceImageBase64
                ) { onProfileSelected(conv) }
                profileRow.addView(avatar)
            }

            profileScroll.addView(profileRow)
            root.addView(profileScroll)
        }

        // Quick Mode button
        val quickBtn = GradientButton.create(context, "⚡ Modo Rápido — sem perfil", heightDp = 36, textSizeSp = 12f) {
            onQuickMode()
        }
        root.addView(quickBtn)

        container.addView(root)
    }

    private fun makeMiniKeyButton(label: String, onClick: () -> Unit): TextView {
        val size = (24 * density).toInt()
        val bg = GradientDrawable().apply {
            setColor(Theme.cardBg)
            cornerRadius = 4 * density
        }
        return TextView(context).apply {
            text = label
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            background = bg
            layoutParams = LinearLayout.LayoutParams(size, size).apply {
                setMargins((1.5f * density).toInt(), 0, (1.5f * density).toInt(), 0)
            }
            setOnClickListener { onClick() }
        }
    }
}
