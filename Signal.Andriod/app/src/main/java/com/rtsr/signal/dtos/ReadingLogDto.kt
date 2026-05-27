package com.rtsr.signal.dtos

data class ReadingLogDto(
    val readingName: String,
    val readingValue: String,
    val readingUnit: String?,
    val writeDateTime: String
)