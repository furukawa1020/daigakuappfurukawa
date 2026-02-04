package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.AggDao
import com.hatake.daigakuos.data.local.dao.NodeDao
import com.hatake.daigakuos.data.local.entity.DailyAggEntity
import com.hatake.daigakuos.data.local.entity.NodeType
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject

/**
 * Centralized use case for updating daily aggregation efficiently.
 * Eliminates duplicate code and improves maintainability.
 */
class UpdateDailyAggregationUseCase @Inject constructor(
    private val aggDao: AggDao,
    private val nodeDao: NodeDao
) {
    suspend operator fun invoke(
        nodeId: String?,
        points: Double,
        selfReportMin: Int
    ) {
        val yyyymmdd = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date()).toInt()
        val currentAgg = aggDao.getAgg(yyyymmdd) ?: DailyAggEntity(yyyymmdd = yyyymmdd)
        
        // Get node type and update corresponding category
        val (pStudy, pResearch, pMake, pAdmin) = calculatePointsByType(
            nodeId = nodeId,
            points = points,
            currentAgg = currentAgg
        )
        
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
    }
    
    private suspend fun calculatePointsByType(
        nodeId: String?,
        points: Double,
        currentAgg: DailyAggEntity
    ): PointsDistribution {
        var pStudy = currentAgg.pointsStudy
        var pResearch = currentAgg.pointsResearch
        var pMake = currentAgg.pointsMake
        var pAdmin = currentAgg.pointsAdmin
        
        if (nodeId != null) {
            val nodeType = nodeDao.getNodeById(nodeId)?.type
            if (nodeType != null) {
                try {
                    when (NodeType.valueOf(nodeType)) {
                        NodeType.STUDY -> pStudy += points
                        NodeType.RESEARCH -> pResearch += points
                        NodeType.MAKE -> pMake += points
                        NodeType.ADMIN -> pAdmin += points
                    }
                } catch (e: IllegalArgumentException) {
                    // Invalid enum value - treat as admin for consistency with ad-hoc sessions
                    pAdmin += points
                }
            } else {
                pAdmin += points
            }
        } else {
            // Ad-hoc session without a node - categorize as admin
            pAdmin += points
        }
        
        return PointsDistribution(pStudy, pResearch, pMake, pAdmin)
    }
    
    private data class PointsDistribution(
        val study: Double,
        val research: Double,
        val make: Double,
        val admin: Double
    )
}
