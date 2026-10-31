using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TuGoalAPI.Data;

namespace TuGoalAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EstatisticasController : ControllerBase
    {
        private readonly TuGoalDbContext _context;

        public EstatisticasController(TuGoalDbContext context)
        {
            _context = context;
        }

        [HttpGet("classificacao")]
        public async Task<IActionResult> GetClassificacao()
        {
            var equipas = await _context.Equipas.Where(e => e.Ativo).ToListAsync();
            var jogos = await _context.Jogos.Where(j => j.Estado_Jogo == "Terminado").ToListAsync();

            var tabela = equipas.Select(e => new
            {
                Equipa = e.Nome,
                Emblema = e.Emblema,
                JogosDisputados = jogos.Count(j => j.ID_Equipa_Casa == e.ID_Equipa || j.ID_Equipa_Fora == e.ID_Equipa),
                Vitorias = jogos.Count(j => (j.ID_Equipa_Casa == e.ID_Equipa && j.Golos_Casa > j.Golos_Fora) || (j.ID_Equipa_Fora == e.ID_Equipa && j.Golos_Fora > j.Golos_Casa)),
                Empates = jogos.Count(j => (j.ID_Equipa_Casa == e.ID_Equipa || j.ID_Equipa_Fora == e.ID_Equipa) && j.Golos_Casa == j.Golos_Fora),
                Derrotas = jogos.Count(j => (j.ID_Equipa_Casa == e.ID_Equipa && j.Golos_Casa < j.Golos_Fora) || (j.ID_Equipa_Fora == e.ID_Equipa && j.Golos_Fora < j.Golos_Casa)),
                GolosMarcados = jogos.Where(j => j.ID_Equipa_Casa == e.ID_Equipa).Sum(j => j.Golos_Casa ?? 0) + jogos.Where(j => j.ID_Equipa_Fora == e.ID_Equipa).Sum(j => j.Golos_Fora ?? 0),
                GolosSofridos = jogos.Where(j => j.ID_Equipa_Casa == e.ID_Equipa).Sum(j => j.Golos_Fora ?? 0) + jogos.Where(j => j.ID_Equipa_Fora == e.ID_Equipa).Sum(j => j.Golos_Casa ?? 0)
            }).Select(c => new
            {
                c.Equipa,
                c.Emblema,
                c.JogosDisputados,
                c.Vitorias,
                c.Empates,
                c.Derrotas,
                c.GolosMarcados,
                c.GolosSofridos,
                DiferencaGolos = c.GolosMarcados - c.GolosSofridos,
                Pontos = (c.Vitorias * 3) + (c.Empates * 1)
            })
            .OrderByDescending(c => c.Pontos)
            .ThenByDescending(c => c.DiferencaGolos)
            .ToList();

            return Ok(tabela);
        }
    }
}