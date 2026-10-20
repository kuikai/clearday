package com.yourname.clearday

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.DateFormat
import java.util.Calendar
import java.util.Date

data class WidgetTask(val title: String, val dueMillis: Long, val hasTime: Boolean)

data class WidgetBoard(val opened: Boolean, val tasks: List<WidgetTask>)

object TodayWidgetViews {
    private const val prefsName = "FlutterSharedPreferences"
    private const val prefsKey = "flutter.clearday_widget_tasks"
    private const val visibleLines = 5
    private const val maxOverdueLines = 3

    fun build(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.today_widget)
        val board = readBoard(context)
        val now = Calendar.getInstance()
        val overdue = board.tasks.filter { isBeforeDay(it.dueMillis, now) }.sortedBy { it.dueMillis }
        val today = board.tasks.filter { isSameDay(it.dueMillis, now) }.sortedBy { it.dueMillis }
        bind(views, board.opened, overdue, today)
        views.setOnClickPendingIntent(R.id.widget_root, openApp(context))
        return views
    }

    private fun bind(
        views: RemoteViews,
        opened: Boolean,
        overdue: List<WidgetTask>,
        today: List<WidgetTask>,
    ) {
        val shownOverdue = overdue.take(maxOverdueLines.coerceAtMost(visibleLines))
        val shownToday = today.take(visibleLines - shownOverdue.size)
        val hidden = (overdue.size - shownOverdue.size) + (today.size - shownToday.size)
        val remaining = overdue.size + today.size
        bindCount(views, remaining)
        setLines(views, R.id.widget_overdue, shownOverdue)
        setLines(views, R.id.widget_today, shownToday)
        bindMore(views, hidden)
        views.setTextViewText(
            R.id.widget_empty,
            if (opened) "Nothing due today" else "Open ClearDay",
        )
        views.setViewVisibility(
            R.id.widget_empty,
            if (remaining == 0) View.VISIBLE else View.GONE,
        )
    }

    private fun bindCount(views: RemoteViews, remaining: Int) {
        if (remaining == 0) {
            views.setViewVisibility(R.id.widget_count, View.GONE)
            return
        }
        val label = if (remaining == 1) "1 left" else "$remaining left"
        views.setViewVisibility(R.id.widget_count, View.VISIBLE)
        views.setTextViewText(R.id.widget_count, label)
    }

    private fun bindMore(views: RemoteViews, hidden: Int) {
        if (hidden == 0) {
            views.setViewVisibility(R.id.widget_more, View.GONE)
            return
        }
        val label = if (hidden == 1) "and 1 more" else "and $hidden more"
        views.setViewVisibility(R.id.widget_more, View.VISIBLE)
        views.setTextViewText(R.id.widget_more, label)
    }

    private fun setLines(views: RemoteViews, viewId: Int, tasks: List<WidgetTask>) {
        if (tasks.isEmpty()) {
            views.setViewVisibility(viewId, View.GONE)
            return
        }
        views.setViewVisibility(viewId, View.VISIBLE)
        views.setTextViewText(viewId, tasks.joinToString("\n") { line(it) })
    }

    private fun line(task: WidgetTask): String {
        if (!task.hasTime) {
            return task.title
        }
        val clock = DateFormat.getTimeInstance(DateFormat.SHORT).format(Date(task.dueMillis))
        return "${task.title}  $clock"
    }

    private fun readBoard(context: Context): WidgetBoard {
        val raw = context
            .getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .getString(prefsKey, null)
        if (raw == null) {
            return WidgetBoard(opened = false, tasks = emptyList())
        }
        return WidgetBoard(opened = true, tasks = parseTasks(raw))
    }

    private fun parseTasks(raw: String): List<WidgetTask> {
        return try {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.optJSONObject(index) ?: continue
                    val title = item.optString("t").trim()
                    if (title.isEmpty() || !item.has("d")) {
                        continue
                    }
                    add(WidgetTask(title, item.getLong("d"), item.optBoolean("h", false)))
                }
            }
        } catch (error: Exception) {
            emptyList()
        }
    }

    private fun isSameDay(millis: Long, now: Calendar): Boolean {
        val due = dayOf(millis)
        return due.get(Calendar.YEAR) == now.get(Calendar.YEAR) &&
            due.get(Calendar.DAY_OF_YEAR) == now.get(Calendar.DAY_OF_YEAR)
    }

    private fun isBeforeDay(millis: Long, now: Calendar): Boolean {
        val due = dayOf(millis)
        if (due.get(Calendar.YEAR) != now.get(Calendar.YEAR)) {
            return due.get(Calendar.YEAR) < now.get(Calendar.YEAR)
        }
        return due.get(Calendar.DAY_OF_YEAR) < now.get(Calendar.DAY_OF_YEAR)
    }

    private fun dayOf(millis: Long): Calendar {
        return Calendar.getInstance().apply { timeInMillis = millis }
    }

    private fun openApp(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
