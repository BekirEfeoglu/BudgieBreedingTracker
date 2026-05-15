package com.budgiebreeding.budgie_breeding_tracker.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class BudgieDashboardWidget : GlanceAppWidget() {
    override val stateDefinition: GlanceStateDefinition<*>?
        get() = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceTheme {
                BudgieDashboardContent(currentState())
            }
        }
    }
}

class BudgieDashboardWidgetReceiver : HomeWidgetGlanceWidgetReceiver<BudgieDashboardWidget>() {
    override val glanceAppWidget = BudgieDashboardWidget()
}

@Composable
private fun BudgieDashboardContent(currentState: HomeWidgetGlanceState) {
    val prefs = currentState.preferences
    val eggTurningCount = prefs.getInt("egg_turning_count", 0)
    val activeBreedingsCount = prefs.getInt("active_breedings_count", 0)
    val nextTurningLabel = prefs.getString("next_turning_label", "") ?: ""
    val hasWorkToday = prefs.getBoolean("has_work_today", false)

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(Color(0xFFF8F7FF)))
            .padding(14.dp),
        verticalAlignment = Alignment.Top,
        horizontalAlignment = Alignment.Start,
    ) {
        Text(
            text = "BudgieTrack",
            style = TextStyle(
                color = ColorProvider(Color(0xFF111827)),
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
            ),
        )
        Spacer(modifier = GlanceModifier.height(10.dp))
        Row(modifier = GlanceModifier.fillMaxWidth()) {
            MetricColumn(
                value = eggTurningCount.toString(),
                label = "Yumurta",
            )
            Spacer(modifier = GlanceModifier.width(12.dp))
            MetricColumn(
                value = activeBreedingsCount.toString(),
                label = "Ureme",
            )
        }
        Spacer(modifier = GlanceModifier.height(10.dp))
        Text(
            text = if (hasWorkToday && nextTurningLabel.isNotBlank()) {
                "Sonraki cevirme $nextTurningLabel"
            } else if (hasWorkToday) {
                "Bugun kontrol var"
            } else {
                "Bugun rutin yok"
            },
            style = TextStyle(
                color = ColorProvider(Color(0xFF4B5563)),
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
            ),
        )
    }
}

@Composable
private fun MetricColumn(value: String, label: String) {
    Column {
        Text(
            text = value,
            style = TextStyle(
                color = ColorProvider(Color(0xFF1D4ED8)),
                fontSize = 26.sp,
                fontWeight = FontWeight.Bold,
            ),
        )
        Text(
            text = label,
            style = TextStyle(
                color = ColorProvider(Color(0xFF6B7280)),
                fontSize = 12.sp,
            ),
        )
    }
}
