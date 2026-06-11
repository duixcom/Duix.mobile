package ai.guiji.duix.test.ui.adapter

import ai.guiji.duix.test.databinding.ItemModelSelectorBinding
import ai.guiji.duix.test.model.AvatarModel
import android.annotation.SuppressLint
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView


class ModelSelectorAdapter(
    private val mList: ArrayList<AvatarModel>,
    private val callback: Callback
) : RecyclerView.Adapter<ModelSelectorAdapter.ItemHolder>() {

    private var selectedPosition = -1

    class ItemHolder(val itemBinding: ItemModelSelectorBinding) :
        RecyclerView.ViewHolder(itemBinding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ItemHolder {
        val itemBinding =
            ItemModelSelectorBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ItemHolder(itemBinding)
    }

    @SuppressLint("SetTextI18n")
    override fun onBindViewHolder(holder: ItemHolder, position: Int) {
        val avatar = mList[position]
        holder.itemBinding.tvModelName.text = avatar.name
        holder.itemBinding.tvModelDesc.text = avatar.description

        // 显示头像（如果有）
        if (avatar.avatarResId != 0) {
            holder.itemBinding.ivAvatar.visibility = View.VISIBLE
            holder.itemBinding.ivAvatar.setImageResource(avatar.avatarResId)
        } else {
            holder.itemBinding.ivAvatar.visibility = View.GONE
        }

        // 高亮选中项
        val isSelected = position == selectedPosition
        holder.itemBinding.root.alpha = if (isSelected) 1.0f else 0.85f

        holder.itemBinding.root.setOnClickListener {
            val oldPos = selectedPosition
            selectedPosition = holder.adapterPosition
            if (oldPos >= 0) notifyItemChanged(oldPos)
            notifyItemChanged(selectedPosition)
            callback.onClick(avatar)
        }
    }

    override fun getItemCount(): Int {
        return mList.size
    }

    interface Callback {
        fun onClick(avatar: AvatarModel)
    }
}
