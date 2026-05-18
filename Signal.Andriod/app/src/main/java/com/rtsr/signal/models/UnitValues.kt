package com.rtsr.signal.models

data class UnitValues(val identifier: String,
                      val name: String,
                      var data: Double,
                      val unit: String,
                      var status: Statuses)

