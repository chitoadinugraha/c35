package id.alienai.remote.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import id.alienai.remote.service.RemoteAgentService

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            RemoteAgentService.start(context)
        }
    }
}
