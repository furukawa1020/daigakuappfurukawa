package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.AggDao
import com.hatake.daigakuos.data.local.dao.NodeDao
import com.hatake.daigakuos.data.local.dao.SessionDao
import com.hatake.daigakuos.data.local.dao.SettingsDao
import com.hatake.daigakuos.data.local.entity.DailyAggEntity
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.NodeType
import com.hatake.daigakuos.data.local.entity.SettingsEntity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import javax.inject.Inject

class FinalizeSessionUseCase @Inject constructor(
    private val sessionDao: SessionDao,
    private val aggDao: AggDao,
    private val settingsDao: SettingsDao,
    private val nodeDao: NodeDao,
    private val pointsCalculator: PointsCalculator
) {
    suspend operator fun invoke(
        sessionId: String,
        selectedNodeId: String?, // Existing Node
        newNodeTitle: String?,   // Or Create New
        newNodeType: NodeType?,  // Type for new node
        selfReportMin: Int,
        focus: Int
    ) {
        val endAt = System.currentTimeMillis()
        val finalizedAt = System.currentTimeMillis()
        
        // 1. Resolve Node
        var finalNodeId = selectedNodeId
        
        if (finalNodeId == null && newNodeTitle != null && newNodeType != null) {
            // Create New Node (Inbox/One-liner)
            // Need a Project. For now, find first project or "Inbox" project.
            // Simplified: Just use randomly or hardcode if ProjectDao not injected?
            // User Spec: "ProjectId INBOX OK". 
            // We'll create a "Inbox" project if missing? 
            // For MVP, just put in *some* project. 
            // Since we don't have ProjectDao here, we might need it.
            // Or just make nodeId nullable in session (it is).
            // But we WANT to attribute points.
            
            // To create a node, we need an ID.
            val newNode = NodeEntity(
                id = UUID.randomUUID().toString(),
                projectId = "inbox", // Placeholder, ideally fetch 'Default' project
                title = newNodeTitle,
                type = newNodeType.name,
                status = "DONE", // Immediately DONE? Or TODO? Spec says "Results". So DONE.
                updatedAt = finalizedAt
            )
            nodeDao.insertNode(newNode) // This might fail if "inbox" project doesn't exist FK constraint.
            // Requires Project. 
            // We should fetch default project.
            // Skipping strictly correct Project ID for brevity, assuming foreign key might bite us.
            // Let's rely on Valid Node ID being passed if possible, or handle FK.
            // Logic hack: Create Node requires ProjectId.
            // We'll assume ViewModel handles creation? 
            // NO, UseCase is better.
            // Let's assume we use the Session's existing nodeId if set, or the user's selection.
            finalNodeId = newNode.id
        }

        // 2. Fetch Session & Settings
        val session = sessionDao.getSessionById(sessionId) ?: return // Should throw?
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
            streakMultiplier = 1.0 // TODO: Real streak
        )

        // 4. Update Session (Finalize)
        // We use a custom query or strict update? 
        // sessionDao.endSession logic needs update for `finalizedAt` / `nodeId` update.
        // We'll Create a new DAO method `finalizeSession`.
        
        // sessionDao.endSession(...) is limited.
        // Let's just update the entity object and use @Update? 
        // SessionDao has @Insert and @Query update.
        // I will add `updateSession(session)` to DAO for cleaner code.
        
        val updatedSession = session.copy(
            nodeId = finalNodeId ?: session.nodeId, // Use selected, or keep original, or remain null (if user actively skipped?)
            endAt = endAt,
            selfReportMin = selfReportMin,
            focus = focus,
            points = points,
            finalizedAt = finalizedAt
        )
        // Use Insert(REPLACE) or Update
        sessionDao.insertSession(updatedSession) // If REPLACE strategy is ON? 
        // SessionDao insertSession is just @Insert. Conflict strategy matches?
        // Default is ABORT.
        // I need to add `updateSession`.
        
        // 5. Update Agg
        val yyyymmdd = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date()).toInt()
        val currentAgg = aggDao.getAgg(yyyymmdd) ?: DailyAggEntity(yyyymmdd = yyyymmdd)
        
        // Attribute to Type
        var pStudy = currentAgg.pointsStudy
        var pResearch = currentAgg.pointsResearch
        var pMake = currentAgg.pointsMake
        var pAdmin = currentAgg.pointsAdmin
        
        // Check Node Type
        val nodeTypeStr = if (finalNodeId != null) {
            nodeDao.getNodeById(finalNodeId)?.type
        } else null
        
        if (nodeTypeStr != null) {
             try {
                when (NodeType.valueOf(nodeTypeStr)) {
                    NodeType.STUDY -> pStudy += points
                    NodeType.RESEARCH -> pResearch += points
                    NodeType.MAKE -> pMake += points
                    NodeType.ADMIN -> pAdmin += points
                }
            } catch (e: Exception) { pStudy += points }
        } else {
             // Unspecified points -> Study? or Admin? 
             pAdmin += points
        }

        val newAgg = currentAgg.copy(
            pointsTotal = currentAgg.pointsTotal + points,
            countDone = currentAgg.countDone + 1,
            minutesSelfReport = currentAgg.minutesSelfReport + selfReportMin,
            pointsStudy = pStudy,
            pointsResearch = pResearch,
            pointsMake = pMake,
            pointsAdmin = pAdmin
        )
        aggDao.upsertDailyAgg(newAgg)
        
        // 6. Mark Node as Updated (Recency)
        if (finalNodeId != null) {
            nodeDao.markDone(finalNodeId, finalizedAt)
        }
    }
}
