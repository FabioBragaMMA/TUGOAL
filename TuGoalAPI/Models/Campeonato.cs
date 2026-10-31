using System.ComponentModel.DataAnnotations;

namespace TuGoalAPI.Models
{
    public class Campeonato
    {
        [Key]
        public int ID_Campeonato { get; set; }
        public string Nome { get; set; }
        public DateTime Data_Inicio { get; set; }
        public DateTime Data_Fim { get; set; }
        public string Estado { get; set; }
    }
}