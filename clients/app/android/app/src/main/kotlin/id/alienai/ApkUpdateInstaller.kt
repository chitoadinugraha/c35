package id.alienai

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileInputStream

object ApkUpdateInstaller {
    private const val TAG = "ApkUpdateInstaller"
    fun canInstall(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return true
        return context.packageManager.canRequestPackageInstalls()
    }

    fun openInstallPermissionSettings(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val intent = Intent(
            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
            Uri.parse("package:${context.packageName}"),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
        }
    }

    fun install(context: Context, apkFile: File): Boolean {
        if (!apkFile.isFile) return false
        // System package UI is more reliable for same-app upgrades (emulator + OEM).
        if (installViaIntent(context, apkFile)) return true
        return tryPackageInstaller(context, apkFile)
    }

    private fun tryPackageInstaller(context: Context, apkFile: File): Boolean {
        val activity = context as? Activity ?: return false
        return try {
            val installer = context.packageManager.packageInstaller
            val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                params.setAppPackageName(context.packageName)
                params.setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_REQUIRED)
            }
            val sessionId = installer.createSession(params)
            val session = installer.openSession(sessionId)
            FileInputStream(apkFile).use { input ->
                session.openWrite("base", 0, apkFile.length()).use { out ->
                    input.copyTo(out)
                    session.fsync(out)
                }
            }
            val intent = Intent(activity, activity.javaClass)
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                android.app.PendingIntent.FLAG_MUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                android.app.PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pending = android.app.PendingIntent.getActivity(activity, sessionId, intent, flags)
            session.commit(pending.intentSender)
            session.close()
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun installViaIntent(context: Context, apkFile: File): Boolean {
        val uri: Uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.apkupdate",
            apkFile,
        )
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
        }
        return try {
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}