using System;
using System.Collections.Generic;

namespace Signal.Server.Data.Models;

public partial class user
{
    public int user_id { get; set; }

    public string login { get; set; } = null!;

    public string hashed_password { get; set; } = null!;

    public string second_name { get; set; } = null!;

    public string first_name { get; set; } = null!;

    public string? last_name { get; set; }

    public virtual ICollection<session> sessions { get; set; } = new List<session>();

    public virtual ICollection<role> roles { get; set; } = new List<role>();
}
