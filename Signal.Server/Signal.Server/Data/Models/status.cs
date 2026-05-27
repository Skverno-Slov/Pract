using System;
using System.Collections.Generic;

namespace Signal.Server.Data.Models;

public partial class status
{
    public int status_id { get; set; }

    public string name { get; set; } = null!;

    public virtual ICollection<equipment> equipment { get; set; } = new List<equipment>();

    public virtual ICollection<reading_log> reading_logs { get; set; } = new List<reading_log>();
}
