package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.SessionDao
import com.hatake.daigakuos.data.local.entity.SessionEntity
import javax.inject.Inject
import java.util.UUID

class StartSessionUseCase @Inject constructor(
    private val sessionDao: SessionDao
) {
    suspend operator fun invoke(nodeId: String?, mode: String, onCampus: Boolean): String {
        val id = UUID.randomUUID().toString()
        val session = SessionEntity(
            id = id,
            nodeId = nodeId,
            mode = mode,
            startAt = System.currentTimeMillis(),
            onCampus = onCampus
        )
        sessionDao.insertSession(session)
        return id
    }
}
