using System;
using System.Collections.Generic;

namespace Signal.Server.Data.Models;

public partial class equipment
{
    public int equipment_id { get; set; }

    public int status_id { get; set; }

    public string serial_number { get; set; } = null!;

    public string name { get; set; } = null!;

    public string model { get; set; } = null!;

    public DateTime? last_check_date { get; set; }

    public virtual ICollection<reading_log> reading_logs { get; set; } = new List<reading_log>();

    public virtual status status { get; set; } = null!;
}
