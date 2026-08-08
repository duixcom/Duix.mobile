package ai.guiji.duix.test.ui.dialog

import ai.guiji.duix.test.R
import ai.guiji.duix.test.databinding.DialogModelSelectorBinding
import ai.guiji.duix.test.model.AvatarModel
import ai.guiji.duix.test.ui.adapter.ModelSelectorAdapter
import android.app.Dialog
import android.content.Context
import android.os.Bundle
import android.view.ViewGroup
import android.view.Window
import android.view.WindowManager


class ModelSelectorDialog(
    mContext: Context,
    private val officialModels: ArrayList<AvatarModel>,
    private val moreModels: ArrayList<AvatarModel>,
    private val listener: Listener
) : Dialog(mContext, R.style.dialog_center) {

    private lateinit var binding: DialogModelSelectorBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        binding = DialogModelSelectorBinding.inflate(layoutInflater)
        super.setContentView(binding.root)

        // 设置 Dialog 宽度为屏幕 90%
        window?.setLayout(
            (context.resources.displayMetrics.widthPixels * 0.9).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT
        )

        // 推荐形象 - 网格布局
        val officialAdapter = ModelSelectorAdapter(officialModels, object : ModelSelectorAdapter.Callback {
            override fun onClick(avatar: AvatarModel) {
                dismiss()
                listener.onSelect(avatar)
            }
        })
        binding.rvOfficialModels.adapter = officialAdapter

        // 更多模型 - 列表布局
        val moreAdapter = ModelSelectorAdapter(moreModels, object : ModelSelectorAdapter.Callback {
            override fun onClick(avatar: AvatarModel) {
                dismiss()
                listener.onSelect(avatar)
            }
        })
        binding.rvLegacyModels.adapter = moreAdapter

        setCancelable(true)
        setCanceledOnTouchOutside(true)
    }

    interface Listener {
        fun onSelect(avatar: AvatarModel)
    }
}
