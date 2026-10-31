using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TuGoalAPI.Data;
using TuGoalAPI.Models;

namespace TuGoalAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class JogadoresController : ControllerBase
    {
        private readonly TuGoalDbContext _context;

        public JogadoresController(TuGoalDbContext context)
        {
            _context = context;
        }

        // Ver todos os jogadores ativos
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Jogador>>> GetJogadores()
        {
            return await _context.Jogadores
                .Where(j => j.Ativo)
                .OrderBy(j => j.ID_Equipa)
                .ThenBy(j => j.Numero_Camisola)
                .ToListAsync();
        }

        // Ver plantel de uma equipa
        [HttpGet("equipa/{equipaId}")]
        public async Task<ActionResult<IEnumerable<Jogador>>> GetJogadoresPorEquipa(int equipaId)
        {
            var equipaExiste = await _context.Equipas.AnyAsync(e => e.ID_Equipa == equipaId && e.Ativo);
            if (!equipaExiste)
                return NotFound(new { mensagem = "Equipa não encontrada." });

            return await _context.Jogadores
                .Where(j => j.ID_Equipa == equipaId && j.Ativo)
                .OrderBy(j => j.Numero_Camisola)
                .ToListAsync();
        }

        // Administrador adiciona jogador ao plantel
        [Authorize(Roles = "Administrador")]
        [HttpPost]
        public async Task<ActionResult<Jogador>> CriarJogador([FromBody] Jogador novoJogador)
        {
            if (string.IsNullOrWhiteSpace(novoJogador.Nome))
                return BadRequest(new { mensagem = "O nome do jogador é obrigatório." });

            if (string.IsNullOrWhiteSpace(novoJogador.Posicao))
                return BadRequest(new { mensagem = "A posição do jogador é obrigatória." });

            if (novoJogador.Numero_Camisola <= 0)
                return BadRequest(new { mensagem = "O número da camisola tem de ser maior que zero." });

            var equipa = await _context.Equipas
                .FirstOrDefaultAsync(e => e.ID_Equipa == novoJogador.ID_Equipa && e.Ativo);

            if (equipa == null)
                return BadRequest(new { mensagem = "A equipa escolhida não existe ou está inativa." });

            novoJogador.Nome = novoJogador.Nome.Trim();
            novoJogador.Posicao = novoJogador.Posicao.Trim();
            novoJogador.Ativo = true;

            _context.Jogadores.Add(novoJogador);
            await _context.SaveChangesAsync();

            return Ok(novoJogador);
        }

        // Administrador edita jogador
        [Authorize(Roles = "Administrador")]
        [HttpPut("{id}")]
        public async Task<IActionResult> EditarJogador(int id, [FromBody] Jogador jogadorAtualizado)
        {
            var jogador = await _context.Jogadores.FindAsync(id);
            if (jogador == null || !jogador.Ativo)
                return NotFound(new { mensagem = "Jogador não encontrado." });

            var equipaExiste = await _context.Equipas
                .AnyAsync(e => e.ID_Equipa == jogadorAtualizado.ID_Equipa && e.Ativo);

            if (!equipaExiste)
                return BadRequest(new { mensagem = "A equipa escolhida não existe ou está inativa." });

            jogador.Nome = jogadorAtualizado.Nome.Trim();
            jogador.Posicao = jogadorAtualizado.Posicao.Trim();
            jogador.Numero_Camisola = jogadorAtualizado.Numero_Camisola;
            jogador.ID_Equipa = jogadorAtualizado.ID_Equipa;

            await _context.SaveChangesAsync();

            return Ok(new { mensagem = "Jogador atualizado com sucesso!", jogador });
        }

        // Soft delete do jogador
        [Authorize(Roles = "Administrador")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> ApagarJogador(int id)
        {
            var jogador = await _context.Jogadores.FindAsync(id);
            if (jogador == null)
                return NotFound(new { mensagem = "Jogador não encontrado." });

            jogador.Ativo = false;
            await _context.SaveChangesAsync();

            return Ok(new { mensagem = "Jogador removido com sucesso!" });
        }
    }
}
