package com.vgs.showcollect.flutter.vgs_show_collect_flutter_demo.view.collect

import android.content.Context
import android.util.Log
import android.widget.TextView
import com.verygoodsecurity.vgscollect.core.HTTPMethod
import com.verygoodsecurity.vgscollect.core.VGSCollect
import com.verygoodsecurity.vgscollect.core.model.network.VGSResponse
import com.verygoodsecurity.vgscollect.widget.VGSEditText
import com.vgs.showcollect.flutter.vgs_show_collect_flutter_demo.MainActivity
import com.vgs.showcollect.flutter.vgs_show_collect_flutter_demo.R
import com.vgs.showcollect.flutter.vgs_show_collect_flutter_demo.view.BaseFormView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class CardCollectFormView constructor(context: Context, messenger: BinaryMessenger?, id: Int) :
        BaseFormView(context, messenger, id, R.layout.pin) {

    override val viewType: String get() = MainActivity.COLLECT_FORM_VIEW_TYPE

    private val vgsCollect = VGSCollect(context, MainActivity.VAULT_ID, MainActivity.ENVIRONMENT)

    private val pinField = rootView.findViewById<VGSEditText>(R.id.pinField)
    init {
        vgsCollect.bindView(pinField)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "redactCard" -> redactCard(result)
            "unfocus" -> {
                pinField.hideKeyboard()
                pinField.clearFocus()
            }
            "focus" -> {
                pinField.requestFocus()
                pinField.showKeyboard()
            }
        }
    }

    private fun setText(call: MethodCall, result: MethodChannel.Result){
        pinField.setText(call.arguments.toString())
        result.success(null)
    }

    private fun redactCard(result: MethodChannel.Result) {
        runOnBackground {
            with(vgsCollect.submit("post", HTTPMethod.POST)) {
                runOnMain {
                    when (this) {
                        is VGSResponse.SuccessResponse -> handleSuccess(this, result)
                        is VGSResponse.ErrorResponse -> result.error(this.code.toString(), this.localizeMessage, this.body)
                    }
                }
            }
        }
    }

    private fun handleSuccess(successResponse: VGSResponse.SuccessResponse, result: MethodChannel.Result) {
        with(successResponse.body?.toJson()) {
            result.success(null)
        }
    }

    private fun String.toJson(): JSONObject? = try {
        JSONObject(this)
    } catch (e: Exception) {
        null
    }
}