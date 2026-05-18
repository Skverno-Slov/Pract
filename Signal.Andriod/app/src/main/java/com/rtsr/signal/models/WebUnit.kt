package com.rtsr.signal.models

import java.time.LocalDateTime

data class WebUnit(val unitId: String,
                   val name: String,
                   val model: String,
                   var lastCheckDateTime: String,
                   var values: List<UnitValues>, var status: Statuses)
