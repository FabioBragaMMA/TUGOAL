using Microsoft.EntityFrameworkCore;
using TuGoalAPI.Models;

namespace TuGoalAPI.Data
{
    public class TuGoalDbContext : DbContext
    {
        public TuGoalDbContext(DbContextOptions<TuGoalDbContext> options) : base(options)
        {
        }

        public DbSet<Utilizador> Utilizadores { get; set; }
        public DbSet<Equipa> Equipas { get; set; }
        public DbSet<Jogador> Jogadores { get; set; }
        public DbSet<CampeonatoEquipa> Campeonato_Equipa { get; set; }
        public DbSet<Campeonato> Campeonatos { get; set; }
        public DbSet<Jogo> Jogos { get; set; }
        public DbSet<EventoJogo> Eventos_Jogo { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<EventoJogo>().ToTable("Eventos_Jogo");
        }
    }
}