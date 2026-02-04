package com.hatake.daigakuos.data.local

import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

/**
 * Database Migration Definitions
 * 
 * This file contains all database migrations to ensure data is preserved
 * when the database schema changes during app updates.
 */

/**
 * Migration from version 1 to version 2
 * 
 * Note: Version 1 never existed in production. This migration is here
 * for safety in case any test/debug builds used version 1.
 */
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(database: SupportSQLiteDatabase) {
        // Version 1 never existed in production, but we provide this
        // migration for safety. Since the app started at version 2,
        // this migration should never run in production.
        
        // If it does run, we need to create all tables from scratch
        // This is the same as the current schema at version 2
        
        // Note: In a real migration scenario, this would only contain
        // the changes between v1 and v2. But since v1 never existed,
        // we leave this empty or could recreate all tables.
        
        // Empty migration is safe here because:
        // 1. Version 1 never shipped to users
        // 2. Room will create all tables if database doesn't exist
    }
}

/**
 * Example migration for future use (version 2 to 3)
 * 
 * When you need to update the database schema:
 * 1. Increment the version number in AppDatabase
 * 2. Create a new migration like this
 * 3. Add it to the database builder in AppModule
 * 
 * Example:
 * val MIGRATION_2_3 = object : Migration(2, 3) {
 *     override fun migrate(database: SupportSQLiteDatabase) {
 *         // Add a new column to sessions table
 *         database.execSQL("ALTER TABLE sessions ADD COLUMN new_field TEXT")
 *     }
 * }
 */
