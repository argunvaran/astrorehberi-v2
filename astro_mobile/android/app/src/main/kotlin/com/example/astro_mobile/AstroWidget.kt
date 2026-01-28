package com.example.astro_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class AstroWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val phase = widgetData.getString("phase", "Connect to App")
                val advice = widgetData.getString("advice", "Open Astro Engine")
                
                setTextViewText(R.id.widget_phase, phase)
                setTextViewText(R.id.widget_advice, advice)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
