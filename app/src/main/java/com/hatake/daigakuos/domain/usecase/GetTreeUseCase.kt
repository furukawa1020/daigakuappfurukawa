package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.NodeDao
import com.hatake.daigakuos.data.local.entity.NodeEntity
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class GetTreeUseCase @Inject constructor(
    private val nodeDao: NodeDao
) {
    operator fun invoke(projectId: String): Flow<List<NodeEntity>> {
        return nodeDao.getTree(projectId)
    }
}
