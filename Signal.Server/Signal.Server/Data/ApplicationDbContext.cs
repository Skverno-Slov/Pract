using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using Signal.Server.Data.Models;

namespace Signal.Server.Data;

public partial class ApplicationDbContext : DbContext
{
    public ApplicationDbContext()
    {
    }

    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<equipment> equipment { get; set; }

    public virtual DbSet<reading_log> reading_logs { get; set; }

    public virtual DbSet<reading_type> reading_types { get; set; }

    public virtual DbSet<role> roles { get; set; }

    public virtual DbSet<session> sessions { get; set; }

    public virtual DbSet<status> statuses { get; set; }

    public virtual DbSet<user> users { get; set; }

    public virtual DbSet<view_latest_equipment_reading> view_latest_equipment_readings { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        => optionsBuilder.UseNpgsql("Host=localhost;Port=5432;Database=signal_track_db;Username=user1;Password=123");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<equipment>(entity =>
        {
            entity.HasKey(e => e.equipment_id).HasName("equipment_pkey");

            entity.HasIndex(e => e.serial_number, "equipment_serial_number_key").IsUnique();

            entity.Property(e => e.model).HasMaxLength(100);
            entity.Property(e => e.name).HasMaxLength(150);
            entity.Property(e => e.serial_number).HasMaxLength(100);

            entity.HasOne(d => d.status).WithMany(p => p.equipment)
                .HasForeignKey(d => d.status_id)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("equipment_status_id_fkey");
        });

        modelBuilder.Entity<reading_log>(entity =>
        {
            entity.HasKey(e => e.reading_log_id).HasName("reading_log_pkey");

            entity.ToTable("reading_log");

            entity.HasIndex(e => new { e.equipment_id, e.write_date_time }, "idx_metrics_device_time").IsDescending(false, true);

            entity.Property(e => e.value).HasMaxLength(50);
            entity.Property(e => e.write_date_time).HasDefaultValueSql("now()");

            entity.HasOne(d => d.equipment).WithMany(p => p.reading_logs)
                .HasForeignKey(d => d.equipment_id)
                .HasConstraintName("reading_log_equipment_id_fkey");

            entity.HasOne(d => d.reading_type).WithMany(p => p.reading_logs)
                .HasForeignKey(d => d.reading_type_id)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("reading_log_reading_type_id_fkey");

            entity.HasOne(d => d.status).WithMany(p => p.reading_logs)
                .HasForeignKey(d => d.status_id)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("reading_log_status_id_fkey");
        });

        modelBuilder.Entity<reading_type>(entity =>
        {
            entity.HasKey(e => e.reading_type_id).HasName("reading_type_pkey");

            entity.ToTable("reading_type");

            entity.HasIndex(e => e.identifier, "reading_type_identifier_key").IsUnique();

            entity.Property(e => e.identifier).HasMaxLength(19);
            entity.Property(e => e.name).HasMaxLength(50);
            entity.Property(e => e.unit).HasMaxLength(20);
        });

        modelBuilder.Entity<role>(entity =>
        {
            entity.HasKey(e => e.role_id).HasName("role_pkey");

            entity.ToTable("role");

            entity.HasIndex(e => e.name, "role_name_key").IsUnique();

            entity.Property(e => e.name).HasMaxLength(50);
        });

        modelBuilder.Entity<session>(entity =>
        {
            entity.HasKey(e => e.session_id).HasName("session_pkey");

            entity.ToTable("session");

            entity.HasIndex(e => e.user_id, "idx_sessions_user");

            entity.HasIndex(e => e.refresh_token, "session_refresh_token_key").IsUnique();

            entity.Property(e => e.device).HasMaxLength(255);

            entity.HasOne(d => d.user).WithMany(p => p.sessions)
                .HasForeignKey(d => d.user_id)
                .HasConstraintName("session_user_id_fkey");
        });

        modelBuilder.Entity<status>(entity =>
        {
            entity.HasKey(e => e.status_id).HasName("status_pkey");

            entity.ToTable("status");

            entity.HasIndex(e => e.name, "status_name_key").IsUnique();

            entity.Property(e => e.name).HasMaxLength(50);
        });

        modelBuilder.Entity<user>(entity =>
        {
            entity.HasKey(e => e.user_id).HasName("user_pkey");

            entity.ToTable("user");

            entity.HasIndex(e => e.login, "user_login_key").IsUnique();

            entity.Property(e => e.first_name).HasMaxLength(100);
            entity.Property(e => e.hashed_password).HasMaxLength(255);
            entity.Property(e => e.last_name).HasMaxLength(100);
            entity.Property(e => e.login).HasMaxLength(50);
            entity.Property(e => e.second_name).HasMaxLength(100);

            entity.HasMany(d => d.roles).WithMany(p => p.users)
                .UsingEntity<Dictionary<string, object>>(
                    "user_role",
                    r => r.HasOne<role>().WithMany()
                        .HasForeignKey("role_id")
                        .HasConstraintName("user_role_role_id_fkey"),
                    l => l.HasOne<user>().WithMany()
                        .HasForeignKey("user_id")
                        .HasConstraintName("user_role_user_id_fkey"),
                    j =>
                    {
                        j.HasKey("user_id", "role_id").HasName("user_role_pkey");
                        j.ToTable("user_role");
                    });
        });

        modelBuilder.Entity<view_latest_equipment_reading>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("view_latest_equipment_readings");

            entity.Property(e => e.label).HasMaxLength(50);
            entity.Property(e => e.metric_key).HasMaxLength(19);
            entity.Property(e => e.status).HasMaxLength(50);
            entity.Property(e => e.unit).HasMaxLength(20);
            entity.Property(e => e.value).HasMaxLength(50);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
