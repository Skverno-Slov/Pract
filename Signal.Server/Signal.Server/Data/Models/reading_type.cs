using System;
using System.Collections.Generic;

namespace Signal.Server.Data.Models;

public partial class reading_type
{
    public int reading_type_id { get; set; }

    public string identifier { get; set; } = null!;

    public string name { get; set; } = null!;

    public string? unit { get; set; }

    public virtual ICollection<reading_log> reading_logs { get; set; } = new List<reading_log>();
}
