package com.sandarutharushka.dawasa

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.Executors

/**
 * Hands a downloaded, already SHA-256-verified APK to Android's own
 * PackageInstaller. Android always shows its confirmation screen
 * (USER_ACTION_REQUIRED); the app never installs anything silently and never
 * loads downloaded code itself.
 */
object ApkUpdates {
    const val METHOD_CHANNEL = "com.sandarutharushka.dawasa/updates"
    const val EVENT_CHANNEL = "com.sandarutharushka.dawasa/install_status"
    const val ACTION_INSTALL_STATUS = "com.sandarutharushka.dawasa.INSTALL_STATUS"

    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    @Volatile
    var events: EventChannel.EventSink? = null

    fun emit(status: String, message: String?) {
        main.post { events?.success(mapOf("status" to status, "message" to message)) }
    }

    fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        val app = context.applicationContext
        when (call.method) {
            "inspectApk", "installApk" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("bad_args", "path missing", null)
                    return
                }
                io.execute {
                    try {
                        val file = checkedFile(app, path)
                        val value: Any? = if (call.method == "inspectApk") {
                            inspect(app, file)
                        } else {
                            install(app, file)
                            null
                        }
                        main.post { result.success(value) }
                    } catch (e: Exception) {
                        main.post { result.error("update_error", e.message, null) }
                    }
                }
            }
            "appSigners" -> result.success(appSigners(app))
            "canRequestInstalls" -> result.success(canRequestInstalls(app))
            "openInstallSettings" -> {
                openInstallSettings(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Only files the app downloaded into its own cache may be installed. */
    private fun checkedFile(context: Context, path: String): File {
        val file = File(path).canonicalFile
        val allowed = File(context.cacheDir, "updates").canonicalPath + File.separator
        require(file.path.startsWith(allowed)) { "APK outside the update folder" }
        require(file.isFile && file.name.endsWith(".apk")) { "not an APK file" }
        return file
    }

    private fun signingFlags(): Int =
        if (Build.VERSION.SDK_INT >= 28) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_SIGNATURES
        }

    private fun inspect(context: Context, file: File): Map<String, Any>? {
        val pm = context.packageManager
        val info: PackageInfo = (
            if (Build.VERSION.SDK_INT >= 33) {
                pm.getPackageArchiveInfo(
                    file.path,
                    PackageManager.PackageInfoFlags.of(signingFlags().toLong()),
                )
            } else {
                @Suppress("DEPRECATION")
                pm.getPackageArchiveInfo(file.path, signingFlags())
            }
        ) ?: return null
        return mapOf(
            "packageName" to info.packageName,
            "versionCode" to versionCode(info),
            "signers" to signers(info),
        )
    }

    private fun appSigners(context: Context): List<String> {
        val pm = context.packageManager
        val info = if (Build.VERSION.SDK_INT >= 33) {
            pm.getPackageInfo(
                context.packageName,
                PackageManager.PackageInfoFlags.of(signingFlags().toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            pm.getPackageInfo(context.packageName, signingFlags())
        }
        return signers(info)
    }

    private fun versionCode(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }

    private fun signers(info: PackageInfo): List<String> {
        val signatures: Array<Signature>? = if (Build.VERSION.SDK_INT >= 28) {
            val signing = info.signingInfo ?: return emptyList()
            if (signing.hasMultipleSigners()) {
                signing.apkContentsSigners
            } else {
                signing.signingCertificateHistory
            }
        } else {
            @Suppress("DEPRECATION")
            info.signatures
        }
        return signatures?.map { sha256(it.toByteArray()) } ?: emptyList()
    }

    private fun sha256(bytes: ByteArray): String =
        MessageDigest.getInstance("SHA-256").digest(bytes)
            .joinToString("") { "%02x".format(it) }

    private fun canRequestInstalls(context: Context): Boolean =
        if (Build.VERSION.SDK_INT >= 26) {
            context.packageManager.canRequestPackageInstalls()
        } else {
            true
        }

    private fun openInstallSettings(context: Context) {
        val intent = if (Build.VERSION.SDK_INT >= 26) {
            Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${context.packageName}"),
            )
        } else {
            Intent(Settings.ACTION_SECURITY_SETTINGS)
        }
        if (context !is android.app.Activity) intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    private fun install(context: Context, file: File) {
        val installer = context.packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(
            PackageInstaller.SessionParams.MODE_FULL_INSTALL,
        )
        params.setAppPackageName(context.packageName)
        params.setSize(file.length())
        if (Build.VERSION.SDK_INT >= 31) {
            params.setRequireUserAction(
                PackageInstaller.SessionParams.USER_ACTION_REQUIRED,
            )
        }
        val sessionId = installer.createSession(params)
        val session = installer.openSession(sessionId)
        try {
            file.inputStream().use { input ->
                session.openWrite("base.apk", 0, file.length()).use { output ->
                    input.copyTo(output)
                    session.fsync(output)
                }
            }
            val intent = Intent(context, InstallResultReceiver::class.java)
                .setAction(ACTION_INSTALL_STATUS)
                .setPackage(context.packageName)
            var flags = PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= 31) {
                // The installer adds the status extras to this explicit intent.
                flags = flags or PendingIntent.FLAG_MUTABLE
            }
            val pending = PendingIntent.getBroadcast(context, sessionId, intent, flags)
            session.commit(pending.intentSender)
        } catch (e: Exception) {
            session.abandon()
            throw e
        } finally {
            session.close()
        }
    }
}

/** Receives the installer session result (not exported). */
class InstallResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ApkUpdates.ACTION_INSTALL_STATUS) return
        val status = intent.getIntExtra(
            PackageInstaller.EXTRA_STATUS,
            PackageInstaller.STATUS_FAILURE,
        )
        val message = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
        when (status) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                val confirm: Intent? = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_INTENT)
                }
                if (confirm != null) {
                    confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(confirm)
                }
                ApkUpdates.emit("pendingUserAction", null)
            }
            PackageInstaller.STATUS_SUCCESS -> ApkUpdates.emit("success", null)
            PackageInstaller.STATUS_FAILURE_ABORTED -> ApkUpdates.emit("aborted", message)
            else -> ApkUpdates.emit("failure", message ?: "status $status")
        }
    }
}
