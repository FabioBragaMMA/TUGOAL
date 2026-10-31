using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using TuGoalAPI.Data;
using TuGoalAPI.Models;

namespace TuGoalAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly TuGoalDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthController(TuGoalDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var user = await _context.Utilizadores
                .FirstOrDefaultAsync(u => u.Email == request.Email && u.PasswordHash == request.Password && u.Ativo);

            if (user == null) return Unauthorized("Email ou password incorretos!");

            var jwtSettings = _configuration.GetSection("Jwt");
            var key = Encoding.ASCII.GetBytes(jwtSettings["Key"]);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.ID_Utilizador.ToString()),
                    new Claim(ClaimTypes.Email, user.Email),
                    new Claim(ClaimTypes.Role, user.Perfil)
                }),
                Expires = DateTime.UtcNow.AddHours(2),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature),
                Issuer = jwtSettings["Issuer"],
                Audience = jwtSettings["Audience"]
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);

            return Ok(new { Token = tokenHandler.WriteToken(token), Nome = user.Nome, Perfil = user.Perfil });
        }

        [HttpPost("registar")]
        public async Task<IActionResult> Registar([FromBody] Utilizador novoUser)
        {
            if (await _context.Utilizadores.AnyAsync(u => u.Email == novoUser.Email))
            {
                return BadRequest("Este email já está registado!");
            }

            novoUser.Ativo = true;
            if (string.IsNullOrEmpty(novoUser.Perfil)) novoUser.Perfil = "Adepto";

            _context.Utilizadores.Add(novoUser);
            await _context.SaveChangesAsync();

            return Ok(new { mensagem = "Conta criada com sucesso!" });
        }
    }
}