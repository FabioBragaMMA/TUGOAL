using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TuGoalAPI.Data;
using TuGoalAPI.Models;

namespace TuGoalAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CampeonatosController : ControllerBase
    {
        private readonly TuGoalDbContext _context;

        public CampeonatosController(TuGoalDbContext context)
        {
            _context = context;
        }

        // lê o nome do campeonato
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Campeonato>>> GetCampeonatos()
        {
            return await _context.Campeonatos.ToListAsync();
        }

        // cria campeonato
        [Authorize(Roles = "Administrador")]
        [HttpPost]
        public async Task<ActionResult<Campeonato>> CriarCampeonato(Campeonato novo)
        {
            _context.Campeonatos.Add(novo);
            await _context.SaveChangesAsync();
            return Ok(novo);
        }

        // inscreve equipa
        [Authorize(Roles = "Administrador")]
        [HttpPost("{idCampeonato}/inscrever/{idEquipa}")]
        public async Task<IActionResult> InscreverEquipa(int idCampeonato, int idEquipa)
        {
            var inscricao = new CampeonatoEquipa { ID_Campeonato = idCampeonato, ID_Equipa = idEquipa };
            _context.Campeonato_Equipa.Add(inscricao);
            await _context.SaveChangesAsync();
            return Ok(new { mensagem = "Equipa inscrita com sucesso!" });
        }
    }
}