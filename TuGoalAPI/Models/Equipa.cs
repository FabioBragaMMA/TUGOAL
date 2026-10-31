using System.ComponentModel.DataAnnotations;

namespace TuGoalAPI.Models
{
    public class Equipa
    {
        [Key]
        public int ID_Equipa { get; set; }
        public string Nome { get; set; }
        public int? Ano_Fundacao { get; set; }
        public string Emblema { get; set; }
        public bool Ativo { get; set; }
    }
}