package com.hatake.daigakuos.data.local.dao

import androidx.room.*
import com.hatake.daigakuos.data.local.entity.WalletEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface WalletDao {
    @Query("SELECT * FROM wallet WHERE id = 'singleton'")
    fun getWallet(): Flow<WalletEntity?>

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun initWallet(wallet: WalletEntity = WalletEntity())

    @Query("UPDATE wallet SET mokoCoins = mokoCoins + :amount WHERE id = 'singleton'")
    suspend fun addMokoCoins(amount: Int)

    @Query("UPDATE wallet SET starCrystals = starCrystals + :amount WHERE id = 'singleton'")
    suspend fun addStarCrystals(amount: Int)

    @Query("UPDATE wallet SET campusGems = campusGems + :amount WHERE id = 'singleton'")
    suspend fun addCampusGems(amount: Int)
}
