using System.ComponentModel.DataAnnotations;

namespace TuGoalAPI.Models
{
    public class Utilizador
    {
        [Key]
        public int ID_Utilizador { get; set; }
        public string Nome { get; set; }
        public string Email { get; set; }
        public string PasswordHash { get; set; }
        public string Perfil { get; set; }
        public bool Ativo { get; set; }
    }
}