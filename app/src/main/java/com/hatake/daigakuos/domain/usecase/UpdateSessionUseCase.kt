package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.SessionDao
import javax.inject.Inject

class UpdateSessionUseCase @Inject constructor(
    private val sessionDao: SessionDao
) {
    suspend operator fun invoke(sessionId: String, newTitle: String) {
        val session = sessionDao.getSessionById(sessionId)
        if (session != null) {
            // Only updating title for now (Draft Title)
            sessionDao.updateSession(session.copy(draftTitle = newTitle))
        }
    }
}
