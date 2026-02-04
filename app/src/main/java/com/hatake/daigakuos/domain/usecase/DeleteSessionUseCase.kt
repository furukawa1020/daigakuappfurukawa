package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.SessionDao
import javax.inject.Inject

class DeleteSessionUseCase @Inject constructor(
    private val sessionDao: SessionDao
) {
    suspend operator fun invoke(sessionId: String) {
        val session = sessionDao.getSessionById(sessionId)
        if (session != null) {
            sessionDao.deleteSession(session)
        }
    }
}
