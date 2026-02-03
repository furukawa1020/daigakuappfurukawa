package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.NodeDao
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.NodeType
import java.util.UUID
import javax.inject.Inject

class UpsertNodeUseCase @Inject constructor(
    private val nodeDao: NodeDao
) {
    suspend operator fun invoke(
        projectId: String, // Required
        parentId: String? = null,
        title: String,
        type: NodeType, // Enum to String
        minutes: Int = 25
    ) {
        val node = NodeEntity(
            id = UUID.randomUUID().toString(),
            projectId = projectId,
            parentId = parentId,
            title = title,
            type = type.name,
            estimateMin = minutes
        )
        nodeDao.insertNode(node)
    }
}
