package ai.guiji.duix.test.model

import ai.guiji.duix.test.R

/**
 * 数字人形象数据模型
 */
data class AvatarModel(
    val name: String,
    val description: String,
    val url: String,
    val avatarResId: Int = 0  // 头像资源 ID，0 表示无头像
) {
    companion object {
        /**
         * 官方公开的 4 个数字人形象 (v2.0.1) - 推荐使用
         */
        val OFFICIAL_AVATARS = arrayListOf(
            AvatarModel(
                name = "Leo",
                description = "年轻男性 · 休闲风格",
                url = "https://github.com/duixcom/Duix.mobile/releases/download/v2.0.1/Leo.zip",
                avatarResId = R.drawable.avatar_leo
            ),
            AvatarModel(
                name = "Oliver",
                description = "成熟男性 · 商务正装",
                url = "https://github.com/duixcom/Duix.mobile/releases/download/v2.0.1/Oliver.zip",
                avatarResId = R.drawable.avatar_oliver
            ),
            AvatarModel(
                name = "Sofia",
                description = "知性女性 · 白衬衫",
                url = "https://github.com/duixcom/Duix.mobile/releases/download/v2.0.1/Sofia.zip",
                avatarResId = R.drawable.avatar_sofia
            ),
            AvatarModel(
                name = "Lily",
                description = "年轻女性 · 亚洲面孔",
                url = "https://github.com/duixcom/Duix.mobile/releases/download/v2.0.1/Lily.zip",
                avatarResId = R.drawable.avatar_lily
            )
        )

        /**
         * 更多可用模型 (v1.0.0)
         */
        val MORE_MODELS = arrayListOf(
            AvatarModel(
                name = "bendi3",
                description = "通用形象",
                url = "https://github.com/duixcom/Duix-Mobile/releases/download/v1.0.0/bendi3_20240518.zip"
            ),
            AvatarModel(
                name = "airuike",
                description = "通用形象",
                url = "https://github.com/duixcom/Duix-Mobile/releases/download/v1.0.0/airuike_20240409.zip"
            ),
            AvatarModel(
                name = "ddzh",
                description = "数字人形象",
                url = "https://github.com/duixcom/Duix-Mobile/releases/download/v1.0.0/ddzh.zip"
            ),
            AvatarModel(
                name = "shuziren_v2",
                description = "数字人 v2",
                url = "https://github.com/duixcom/Duix-Mobile/releases/download/v1.0.0/shuziren_v2.zip"
            ),
            AvatarModel(
                name = "St_yxm",
                description = "加密优化版",
                url = "https://github.com/duixcom/Duix-Mobile/releases/download/v1.0.0/St_yxm_encrypted_optim.zip"
            ),
            AvatarModel(
                name = "Zyynv",
                description = "1080p 高清",
                url = "https://github.com/duixcom/Duix-Mobile/releases/download/v1.0.0/Zyynv_0515_1080p.zip"
            )
        )
    }
}
