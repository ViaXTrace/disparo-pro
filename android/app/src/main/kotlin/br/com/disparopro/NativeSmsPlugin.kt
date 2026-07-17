package br.com.disparopro

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Plugin Flutter para envio de SMS nativo via android.telephony.SmsManager.
 * Completamente gratuito — usa o plano do usuário, sem API externa.
 */
class NativeSmsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    ActivityAware, PluginRegistry.RequestPermissionsResultListener {

    companion object {
        const val CHANNEL = "br.com.disparopro/native_sms"
        private const val SMS_PERMISSION_REQUEST = 7001
    }

    private lateinit var channel: MethodChannel
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    // ── FlutterPlugin ────────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = binding
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        flutterPluginBinding = null
    }

    // ── ActivityAware ────────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    // ── MethodCallHandler ────────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val context = flutterPluginBinding?.applicationContext ?: run {
            result.error("NO_CONTEXT", "Plugin não inicializado", null)
            return
        }

        when (call.method) {
            "sendSms" -> {
                val to = call.argument<String>("to")
                val body = call.argument<String>("body")
                if (to.isNullOrBlank() || body.isNullOrBlank()) {
                    result.error("INVALID_ARGS", "Parâmetros 'to' e 'body' são obrigatórios", null)
                    return
                }
                if (!hasSmsPermission(context)) {
                    result.error("PERMISSION_DENIED", "Permissão SEND_SMS não concedida", null)
                    return
                }
                try {
                    val smsManager = getSmsManager(context)
                    if (body.length > 160) {
                        val parts = smsManager.divideMessage(body)
                        smsManager.sendMultipartTextMessage(to, null, parts, null, null)
                    } else {
                        smsManager.sendTextMessage(to, null, body, null, null)
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SMS_ERROR", e.message ?: "Erro desconhecido", null)
                }
            }

            "checkPermission" -> {
                result.success(hasSmsPermission(context))
            }

            "requestPermission" -> {
                val activity = activityBinding?.activity
                if (activity == null) {
                    result.error("NO_ACTIVITY", "Activity não disponível", null)
                    return
                }
                if (hasSmsPermission(context)) {
                    result.success(true)
                    return
                }
                pendingPermissionResult = result
                ActivityCompat.requestPermissions(
                    activity,
                    arrayOf(Manifest.permission.SEND_SMS),
                    SMS_PERMISSION_REQUEST
                )
            }

            else -> result.notImplemented()
        }
    }

    // ── Permission result ────────────────────────────────────────────────────

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == SMS_PERMISSION_REQUEST) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
            return true
        }
        return false
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    private fun hasSmsPermission(context: android.content.Context): Boolean =
        ContextCompat.checkSelfPermission(
            context, Manifest.permission.SEND_SMS
        ) == PackageManager.PERMISSION_GRANTED

    @Suppress("DEPRECATION")
    private fun getSmsManager(context: android.content.Context): SmsManager =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            context.getSystemService(SmsManager::class.java)
        else
            SmsManager.getDefault()
}
