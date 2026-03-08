package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.NodeDao
import com.hatake.daigakuos.data.local.dao.SessionDao
import com.hatake.daigakuos.data.local.dao.SettingsDao
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.NodeType
import com.hatake.daigakuos.data.local.entity.SettingsEntity
import java.util.UUID
import javax.inject.Inject

data class SessionResult(
    val node: NodeEntity,
    val points: Double,
    val isOnCampus: Boolean,
    val streak: Int,
    val earnedMokoCoins: Int = 0,
    val earnedStarCrystals: Int = 0,
    val earnedCampusGems: Int = 0,
    val unlockedAchievements: List<String> = emptyList()
)

class FinalizeSessionUseCase @Inject constructor(
    private val sessionDao: SessionDao,
    private val settingsDao: SettingsDao,
    private val nodeDao: NodeDao,
    private val projectDao: com.hatake.daigakuos.data.local.dao.ProjectDao,
    private val walletDao: com.hatake.daigakuos.data.local.dao.WalletDao,
    private val pointsCalculator: PointsCalculator,
    private val updateDailyAggregationUseCase: UpdateDailyAggregationUseCase,
    private val checkAchievementsUseCase: CheckAchievementsUseCase
) {
    suspend operator fun invoke(
        sessionId: String,
        selectedNodeId: String?,
        newNodeTitle: String?,
        newNodeType: NodeType?,
        selfReportMin: Int,
        focus: Int
    ): SessionResult? {
        val endAt = System.currentTimeMillis()
        val finalizedAt = System.currentTimeMillis()
        
        // 1. Resolve Node
        var finalNodeId = selectedNodeId
        
        if (finalNodeId == null && newNodeTitle != null && newNodeType != null) {
            val defaultProject = projectDao.findDefaultProject()
            val projectId = defaultProject?.id ?: "inbox"
            
            val newNode = NodeEntity(
                id = UUID.randomUUID().toString(),
                projectId = projectId,
                title = newNodeTitle,
                type = newNodeType.name,
                status = "DONE",
                updatedAt = finalizedAt
            )
            nodeDao.insertNode(newNode)
            finalNodeId = newNode.id
        }

        // 2. Fetch Session & Settings
        val session = sessionDao.getSessionById(sessionId) 
            ?: throw IllegalStateException("Session with id $sessionId not found")
        val onCampus = session.onCampus
        
        var settings = settingsDao.getSettings()
        if (settings == null) {
            settings = SettingsEntity()
            settingsDao.insertSettings(settings)
        }

        // 3. Calc Points
        val points = pointsCalculator.computePoints(
            selfReportMin = selfReportMin,
            focus = focus,
            onCampus = onCampus,
            campusBaseMultiplier = settings.campusBaseMultiplier,
            streakMultiplier = 1.0
        )

        // 4. Update Session
        val updatedSession = session.copy(
            nodeId = finalNodeId ?: session.nodeId,
            endAt = endAt,
            selfReportMin = selfReportMin,
            focus = focus,
            points = points,
            finalizedAt = finalizedAt
        )
        sessionDao.updateSession(updatedSession)
        
        // 5. Update Aggregation (using centralized use case)
        updateDailyAggregationUseCase(finalNodeId, points, selfReportMin)
        
        // 6. Mark Node as Updated
        var finalNodeObj: NodeEntity? = null
        if (finalNodeId != null) {
            nodeDao.markDone(finalNodeId, finalizedAt)
            finalNodeObj = nodeDao.getNodeById(finalNodeId)
        }
        
        // 7. Wallet Rewards
        walletDao.initWallet() // Ensure wallet exists
        val mokoCoinsEarned = selfReportMin
        val starCrystalsEarned = if (selfReportMin >= 60 && focus >= 4) 1 else 0
        val campusGemsEarned = if (onCampus) 1 else 0

        walletDao.addMokoCoins(mokoCoinsEarned)
        if (starCrystalsEarned > 0) walletDao.addStarCrystals(starCrystalsEarned)
        if (campusGemsEarned > 0) walletDao.addCampusGems(campusGemsEarned)

        // 8. Evaluate Achievements
        // Note: In MVP, streak is fixed to 1 since actual streak calculation needs DailyAgg tracking
        val streak = 1 
        val totalSessionsCount = sessionDao.getSessionCount()
        val totalPoints = sessionDao.getTotalPoints()
        
        val newlyUnlocked = checkAchievementsUseCase(
            session = updatedSession,
            streak = streak,
            totalSessionsCount = totalSessionsCount,
            totalPoints = totalPoints,
            isOnCampus = onCampus
        )

        return finalNodeObj?.let {
            SessionResult(
                node = it,
                points = points,
                isOnCampus = onCampus,
                streak = streak,
                earnedMokoCoins = mokoCoinsEarned,
                earnedStarCrystals = starCrystalsEarned,
                earnedCampusGems = campusGemsEarned,
                unlockedAchievements = newlyUnlocked
            )
        }
    }
}
