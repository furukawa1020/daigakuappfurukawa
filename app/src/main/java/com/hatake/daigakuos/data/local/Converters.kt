package com.hatake.daigakuos.data.local

import androidx.room.TypeConverter
import com.hatake.daigakuos.data.local.entity.*

class Converters {
    @TypeConverter
    fun fromProjectType(value: ProjectType): String = value.name
    @TypeConverter
    fun toProjectType(value: String): ProjectType = ProjectType.valueOf(value)

    @TypeConverter
    fun fromNodeStatus(value: NodeStatus): String = value.name
    @TypeConverter
    fun toNodeStatus(value: String): NodeStatus = NodeStatus.valueOf(value)

    @TypeConverter
    fun fromMode(value: Mode): String = value.name
    @TypeConverter
    fun toMode(value: String): Mode = Mode.valueOf(value)

    @TypeConverter
    fun fromRecoveryType(value: RecoveryType): String = value.name
    @TypeConverter
    fun toRecoveryType(value: String): RecoveryType = RecoveryType.valueOf(value)
}
