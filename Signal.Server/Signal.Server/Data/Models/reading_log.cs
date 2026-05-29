using Signal.Server.Data.Models.Models;
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

    public virtual Equipment equipment { get; set; } = null!;

    public virtual ReadingType reading_type { get; set; } = null!;

    public virtual Status status { get; set; } = null!;
}
