using System;
using System.Collections.Generic;

namespace Signal.Server.Data.Models;

public partial class session
{
    public int session_id { get; set; }

    public int user_id { get; set; }

    public string refresh_token { get; set; } = null!;

    public string? device { get; set; }

    public DateTime session_end_date_time { get; set; }

    public virtual user user { get; set; } = null!;
}
