using System;
using System.Collections.Generic;

namespace Signal.Server.Data.Models;

public partial class role
{
    public int role_id { get; set; }

    public string name { get; set; } = null!;

    public virtual ICollection<user> users { get; set; } = new List<user>();
}
