using System;
using System.Collections.Generic;

namespace Signal.Server.Data.Models;

public partial class reading_log
{
    public int reading_log_id { get; set; }

    public int equipment_id { get; set; }

    public int status_id { get; set; }

    public int reading_type_id { get; set; }

    public DateTime write_date_time { get; set; }

    public string value { get; set; } = null!;

    public virtual equipment equipment { get; set; } = null!;

    public virtual reading_type reading_type { get; set; } = null!;

    public virtual status status { get; set; } = null!;
}
