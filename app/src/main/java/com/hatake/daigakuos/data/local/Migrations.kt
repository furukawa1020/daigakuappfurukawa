package com.hatake.daigakuos.data.local

import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

/**
 * Database Migration Definitions
 * 
 * This file contains all database migrations to ensure data is preserved
 * when the database schema changes during app updates.
 * 
 * IMPORTANT: Version 2 is the first production version of the database.
 * No migration from version 1 is needed as version 1 never existed.
 * 
 * Future migrations should be added here when the schema changes.
 */

/**
 * Example migration for future use (version 2 to 3)
 * 
 * When you need to update the database schema:
 * 1. Increment the version number in AppDatabase (e.g., version = 3)
 * 2. Create a new migration like this
 * 3. Add it to the database builder in AppModule
 * 
 * Example:
 * val MIGRATION_2_3 = object : Migration(2, 3) {
 *     override fun migrate(database: SupportSQLiteDatabase) {
 *         // Example: Add a new column to sessions table
 *         database.execSQL("ALTER TABLE sessions ADD COLUMN new_field TEXT")
 *         
 *         // Example: Create a new table
 *         database.execSQL("""
 *             CREATE TABLE IF NOT EXISTS new_table (
 *                 id TEXT PRIMARY KEY NOT NULL,
 *                 data TEXT NOT NULL
 *             )
 *         """.trimIndent())
 *     }
 * }
 * 
 * Then in AppModule.kt:
 * .addMigrations(MIGRATION_2_3)
 */
