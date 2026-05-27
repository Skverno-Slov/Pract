using System;
using System.Collections.Generic;

namespace Signal.Server.Data.Models;

public partial class view_latest_equipment_reading
{
    public int? equipment_id { get; set; }

    public string? metric_key { get; set; }

    public string? label { get; set; }

    public string? value { get; set; }

    public string? unit { get; set; }

    public string? status { get; set; }

    public DateTime? datetime { get; set; }
}
