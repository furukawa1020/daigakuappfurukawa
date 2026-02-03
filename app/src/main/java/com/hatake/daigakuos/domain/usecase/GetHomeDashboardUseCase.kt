package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.AggDao
import com.hatake.daigakuos.data.local.dao.SettingsDao
import com.hatake.daigakuos.data.local.entity.DailyAggEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject

class GetHomeDashboardUseCase @Inject constructor(
    private val aggDao: AggDao,
    private val settingsDao: SettingsDao
) {
    suspend fun getTodayAgg(): DailyAggEntity {
        val yyyymmdd = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date()).toInt()
        return aggDao.getAgg(yyyymmdd) ?: DailyAggEntity(yyyymmdd = yyyymmdd)
    }

    suspend fun getTargetHours(): Int {
        return settingsDao.getSettings()?.weeklyHourTarget ?: 40
    }
}
