/* =====================================================================
   PROJETO: Sistema de Matrícula Acadêmica
   DISCIPLINA: Banco de Dados II (CCO072) — IESB 2026/2
   PROFESSOR: Rodrigo Gonçalves
   
   ARQUIVO: 02-carga_de_dados_iniciais.sql
   DESCRIÇÃO: Script DML para povoamento inicial da base "matricula".
              Insere dados fictícios coerentes para testes de integridade,
              validação de constraints e execução de consultas do projeto.
   
   SGBD: PostgreSQL 17
   BANCO DE DADOS: matricula
   PRÉ-REQUISITO: Executar previamente o script "01_marco1_ddl_esquema.sql"
   
   AUTORES:
     - Alexandre Vieira Da Silva - 2512130008
     - Antônio Alexandre Cavalcante Leite - 2512130086
     - Carlos Eduardo ... (A preencher)
     
   HISTÓRICO DE REVISÕES: Verificar GitHub
     - https://github.com/TotonhoMilk/BD_II
   ===================================================================== */

/* ---------------------------------------------------------------------
   CARGA MÍNIMA EXIGIDA PELO ENUNCIADO (seção 4.1)

       100 alunos · 6 turmas · 300 matrículas

   Esta carga entrega 120 alunos, 12 turmas e ~360 matrículas — acima do
   mínimo, para que as consultas de janela e as recursivas tenham massa
   suficiente. Com apenas 6 turmas, o ranking por turma teria empates
   demais para ser demonstrativo.

   O uso de generate_series é explicitamente permitido pelo enunciado.

   ORDEM DE INSERÇÃO
   A ordem abaixo é a topológica das chaves estrangeiras: nenhuma tabela
   é populada antes daquelas de que depende. Alterá-la quebra a carga.

       campus -> curso -> curriculo -> disciplina -> curriculo_disciplina
              -> pre_requisito -> professor -> sala -> periodo_letivo
              -> feriado -> turma -> turma_horario -> aluno
              -> matricula -> historico -> log_matricula

   IDEMPOTÊNCIA
   TRUNCATE antes de inserir: o script pode rodar repetidamente sem
   duplicar nada. Não remove tabelas — o DDL do 01 continua valendo.

   IDENTIFICADORES
   O DDL declara as PKs como "INT PRIMARY KEY", sem IDENTITY nem SERIAL.
   Os ids são portanto informados explicitamente, derivados do próprio
   generate_series. Isso mantém a carga reproduzível: rodar duas vezes
   produz exatamente os mesmos ids, e a apresentação ao vivo não depende
   de sorte.
   --------------------------------------------------------------------- */

BEGIN;

TRUNCATE TABLE log_matricula, historico, matricula, aluno, turma_horario,
               turma, feriado, periodo_letivo, sala, professor,
               pre_requisito, curriculo_disciplina, disciplina,
               curriculo, curso, campus
        RESTART IDENTITY CASCADE;


/* =====================================================================
   1. CAMPUS
   ===================================================================== */
INSERT INTO campus (campus_id, campus_nome, campus_cidade) VALUES
  (1, 'Asa Sul',    'Brasília'),
  (2, 'Ceilândia',  'Brasília'),
  (3, 'Taguatinga', 'Brasília');


/* =====================================================================
   2. CURSO
   ===================================================================== */
INSERT INTO curso (curso_id, curso_codigo, curso_nome, curso_grau,
                   curso_ch_total, campus_id) VALUES
  (1, 'CCO', 'Ciência da Computação',  'BACHARELADO', 3200, 1),
  (2, 'ENG', 'Engenharia de Software', 'BACHARELADO', 3400, 1),
  (3, 'ADS', 'Análise e Desenvolvimento de Sistemas', 'TECNOLOGO', 2000, 2);


/* =====================================================================
   3. CURRÍCULO

   Dois currículos para Ciência da Computação: 2022 (inativo) e 2026
   (ativo). Exercita o índice parcial que garante um só currículo ativo
   por curso, e sustenta o CA2 da História 5 — o aluno permanece no
   currículo do seu ingresso.
   ===================================================================== */
INSERT INTO curriculo (curriculo_id, curso_id, curriculo_ano_vigencia,
                       curriculo_ativo) VALUES
  (1, 1, 2022, false),
  (2, 1, 2026, true),
  (3, 2, 2026, true),
  (4, 3, 2026, true);


/* =====================================================================
   4. DISCIPLINA

   Catálogo com profundidade de pré-requisitos suficiente para a consulta
   recursiva: a cadeia APC I -> APC II -> Estrutura de Dados -> PAA tem
   quatro níveis.

   disciplina_ch_total é GERADA pelo banco (ch_teorica + ch_pratica) e
   por isso NÃO aparece na lista de colunas — informá-la produz erro.
   ===================================================================== */
INSERT INTO disciplina (disciplina_id, disciplina_codigo, disciplina_nome,
                        disciplina_ch_teorica, disciplina_ch_pratica,
                        disciplina_ementa) VALUES
  ( 1, 'MAT001', 'Cálculo I',                       60,  0, 'Limites, derivadas e integrais de funções reais.'),
  ( 2, 'MAT002', 'Cálculo II',                      60,  0, 'Integrais múltiplas, séries e equações diferenciais.'),
  ( 3, 'MAT010', 'Álgebra Linear',                  60,  0, 'Espaços vetoriais, matrizes e transformações lineares.'),
  ( 4, 'MAT020', 'Matemática Discreta',             60,  0, 'Lógica, conjuntos, relações, grafos e combinatória.'),
  ( 5, 'CCO101', 'Algoritmos e Programação I',      30, 30, 'Lógica de programação, variáveis e controle de fluxo.'),
  ( 6, 'CCO102', 'Algoritmos e Programação II',     30, 30, 'Modularização, recursão, arquivos e ponteiros.'),
  ( 7, 'CCO201', 'Estrutura de Dados',              30, 30, 'Listas, pilhas, filas, árvores e tabelas hash.'),
  ( 8, 'CCO202', 'Projeto e Análise de Algoritmos', 60,  0, 'Complexidade, divisão e conquista, programação dinâmica.'),
  ( 9, 'CCO210', 'Programação Orientada a Objetos', 30, 30, 'Classes, herança, polimorfismo e interfaces.'),
  (10, 'CCO301', 'Banco de Dados I',                30, 30, 'Modelo relacional, normalização, álgebra relacional e SQL.'),
  (11, 'CCO302', 'Banco de Dados II',               30, 30, 'Transações, concorrência, índices, administração e recuperação.'),
  (12, 'CCO310', 'Engenharia de Software',          60,  0, 'Processos, requisitos, modelagem e qualidade de software.'),
  (13, 'CCO320', 'Sistemas Operacionais',           45, 15, 'Processos, memória, sistemas de arquivos e escalonamento.'),
  (14, 'CCO330', 'Redes de Computadores',           45, 15, 'Camadas, protocolos, endereçamento e roteamento.'),
  (15, 'CCO401', 'Inteligência Artificial',         45, 15, 'Busca, representação de conhecimento e aprendizado de máquina.'),
  (16, 'CCO410', 'Compiladores',                    45, 15, 'Análise léxica, sintática, semântica e geração de código.'),
  (17, 'CCO420', 'Computação Gráfica',              30, 30, 'Rasterização, transformações geométricas e iluminação.'),
  (18, 'CCO430', 'Segurança da Informação',         45, 15, 'Criptografia, autenticação, controle de acesso e auditoria.'),
  (19, 'HUM001', 'Metodologia Científica',          30,  0, 'Método científico, pesquisa e produção acadêmica.'),
  (20, 'HUM010', 'Ética e Legislação',              30,  0, 'Ética profissional, LGPD e propriedade intelectual.');


/* =====================================================================
   5. CURRICULO_DISCIPLINA

   Vincula disciplinas aos currículos, distribuídas por período. O tipo
   usa o ENUM tipo_disc_t declarado no DDL ('OBR', 'OPT', 'ELET').
   ===================================================================== */
INSERT INTO curriculo_disciplina (curriculo_id, disciplina_id,
                                  curriculo_disciplina_periodo,
                                  curriculo_disciplina_tipo) VALUES
  -- currículo 2026 (ativo) — Ciência da Computação
  (2,  1, 1, 'OBR'), (2,  4, 1, 'OBR'), (2,  5, 1, 'OBR'), (2, 19, 1, 'OBR'),
  (2,  2, 2, 'OBR'), (2,  3, 2, 'OBR'), (2,  6, 2, 'OBR'),
  (2,  7, 3, 'OBR'), (2,  9, 3, 'OBR'), (2, 13, 3, 'OBR'),
  (2,  8, 4, 'OBR'), (2, 10, 4, 'OBR'), (2, 14, 4, 'OBR'),
  (2, 11, 5, 'OBR'), (2, 12, 5, 'OBR'), (2, 18, 5, 'OBR'),
  (2, 15, 6, 'OPT'), (2, 16, 6, 'OPT'), (2, 17, 6, 'OPT'), (2, 20, 6, 'ELET'),

  -- currículo 2022 (inativo), grade reduzida
  (1,  1, 1, 'OBR'), (1,  5, 1, 'OBR'), (1,  6, 2, 'OBR'),
  (1,  7, 3, 'OBR'), (1, 10, 4, 'OBR'), (1, 11, 5, 'OBR');


/* =====================================================================
   6. PRE_REQUISITO

   O grafo que as duas consultas recursivas obrigatórias percorrem.

   Cadeia mais profunda (4 níveis):
       APC I (5) -> APC II (6) -> Estrutura de Dados (7) -> PAA (8)

   Banco de Dados II depende de Banco de Dados I, que depende de
   Estrutura de Dados — outro caminho longo até APC I.

   O CO_REQUISITO (Cálculo II com Álgebra Linear) existe para que a
   consulta de elegibilidade TENHA que distinguir os dois vínculos:
   co-requisito não impede matrícula (CA3 da História 2).
   ===================================================================== */
INSERT INTO pre_requisito (disciplina_id, requisito_id,
                           pre_requisito_vinculo) VALUES
  ( 2,  1, 'PRE_REQUISITO'),   -- Cálculo II         <- Cálculo I
  ( 6,  5, 'PRE_REQUISITO'),   -- APC II             <- APC I
  ( 7,  6, 'PRE_REQUISITO'),   -- Estrutura de Dados <- APC II
  ( 8,  7, 'PRE_REQUISITO'),   -- PAA                <- Estrutura de Dados
  ( 8,  4, 'PRE_REQUISITO'),   -- PAA                <- Matemática Discreta
  ( 9,  6, 'PRE_REQUISITO'),   -- POO                <- APC II
  (10,  7, 'PRE_REQUISITO'),   -- Banco de Dados I   <- Estrutura de Dados
  (11, 10, 'PRE_REQUISITO'),   -- Banco de Dados II  <- Banco de Dados I
  (13,  6, 'PRE_REQUISITO'),   -- Sistemas Operac.   <- APC II
  (14, 13, 'PRE_REQUISITO'),   -- Redes              <- Sistemas Operacionais
  (15,  8, 'PRE_REQUISITO'),   -- IA                 <- PAA
  (15,  3, 'PRE_REQUISITO'),   -- IA                 <- Álgebra Linear
  (16,  8, 'PRE_REQUISITO'),   -- Compiladores       <- PAA
  (17,  3, 'PRE_REQUISITO'),   -- Computação Gráfica <- Álgebra Linear
  (18, 14, 'PRE_REQUISITO'),   -- Segurança          <- Redes
  ( 2,  3, 'CO_REQUISITO');    -- Cálculo II         || Álgebra Linear


/* =====================================================================
   7. PROFESSOR — 12 docentes
   ===================================================================== */
INSERT INTO professor (professor_id, professor_matricula, professor_nome,
                       professor_email, professor_titulacao)
SELECT g,
       'P' || lpad(g::text, 5, '0'),
       (ARRAY['Rodrigo Gonçalves','Marcos Antunes','Patrícia Lemos',
              'Fernanda Dias','Carlos Menezes','Juliana Prado',
              'Ricardo Bastos','Helena Vasconcelos','Paulo Tavares',
              'Sandra Rocha','Eduardo Nunes','Beatriz Camargo'])[g],
       (ARRAY['rodrigo.goncalves','marcos.antunes','patricia.lemos',
              'fernanda.dias','carlos.menezes','juliana.prado',
              'ricardo.bastos','helena.vasconcelos','paulo.tavares',
              'sandra.rocha','eduardo.nunes','beatriz.camargo'])[g]
         || '@iesb.edu.br',
       (ARRAY['DOUTOR','MESTRE','DOUTOR','MESTRE','DOUTOR','MESTRE',
              'ESPECIALISTA','DOUTOR','MESTRE','DOUTOR','MESTRE',
              'ESPECIALISTA'])[g]
  FROM generate_series(1, 12) AS g;


/* =====================================================================
   8. SALA

   Capacidades variadas de propósito: o CA4 da História 4 exige que a
   capacidade comporte as vagas da turma, e salas pequenas tornam essa
   verificação demonstrável.
   ===================================================================== */
INSERT INTO sala (sala_id, campus_id, sala_codigo, sala_capacidade, sala_tipo)
SELECT g,
       1 + (g - 1) % 3,
       (ARRAY['A','B','C'])[1 + (g - 1) % 3] || '-' ||
         lpad((100 + g)::text, 3, '0'),
       (ARRAY[30, 40, 45, 50, 60, 80])[1 + (g - 1) % 6],
       -- sala_tipo é VARCHAR(10) no DDL: 'LABORATORIO' (11 caracteres)
       -- não cabe. O modelo lógico pede o ENUM tipo_sala_t, que não foi
       -- criado — ver 04-ajustes_tipos.sql. Até lá, usa-se a forma
       -- abreviada que respeita o limite declarado.
       CASE WHEN g % 4 = 0 THEN 'LAB'
            WHEN g % 7 = 0 THEN 'AUDITORIO'
            ELSE 'TEORICA' END
  FROM generate_series(1, 15) AS g;


/* =====================================================================
   9. PERÍODO LETIVO

   Quatro semestres, para que a consulta com LAG tenha série temporal
   sobre a qual medir evolução de rendimento.
   ===================================================================== */
INSERT INTO periodo_letivo (periodo_letivo_id, periodo_ano, periodo_semestre,
                            periodo_data_inicio, periodo_data_fim) VALUES
  (1, 2025, 1, '2025-02-10', '2025-06-28'),
  (2, 2025, 2, '2025-08-04', '2025-12-13'),
  (3, 2026, 1, '2026-02-09', '2026-06-27'),
  (4, 2026, 2, '2026-08-03', '2026-12-12');


/* =====================================================================
   10. FERIADO — suspendem aula por campus (requisito R11)
   ===================================================================== */
INSERT INTO feriado (feriado_id, feriado_data, feriado_descricao,
                     campus_id) VALUES
  (1, '2026-09-07', 'Independência do Brasil',    1),
  (2, '2026-10-12', 'Nossa Senhora Aparecida',    1),
  (3, '2026-11-02', 'Finados',                    1),
  (4, '2026-11-15', 'Proclamação da República',   1),
  (5, '2026-11-20', 'Dia da Consciência Negra',   1),
  (6, '2026-11-30', 'Dia do Evangélico (DF)',     2),
  (7, '2026-12-08', 'Nossa Senhora da Conceição', 3);


/* =====================================================================
   11. TURMA — 12 turmas em 2026/2

   O enunciado exige no mínimo 6. São 12 para que o ranking por turma
   tenha grupos suficientes e a consulta de vagas mostre turmas cheias
   e com folga ao mesmo tempo.

   As vagas variam de 25 a 50: as turmas menores enchem, e é nelas que
   a disputa pela última vaga (Marco 2) se manifesta.
   ===================================================================== */
INSERT INTO turma (turma_id, turma_codigo, disciplina_id, periodo_letivo_id,
                   professor_id, turma_turno, turma_vagas) VALUES
  ( 1, 'CCO101-A',  5, 4,  1, 'NOTURNO',  50),
  ( 2, 'CCO101-B',  5, 4,  2, 'MATUTINO', 45),
  ( 3, 'CCO102-A',  6, 4,  3, 'NOTURNO',  40),
  ( 4, 'CCO201-A',  7, 4,  4, 'NOTURNO',  35),
  ( 5, 'CCO210-A',  9, 4,  5, 'NOTURNO',  40),
  ( 6, 'CCO301-A', 10, 4,  6, 'NOTURNO',  35),
  ( 7, 'CCO302-A', 11, 4,  1, 'NOTURNO',  30),
  ( 8, 'CCO302-B', 11, 4,  7, 'MATUTINO', 30),
  ( 9, 'CCO320-A', 13, 4,  8, 'NOTURNO',  40),
  (10, 'CCO330-A', 14, 4,  9, 'NOTURNO',  35),
  (11, 'MAT001-A',  1, 4, 10, 'NOTURNO',  50),
  (12, 'CCO401-A', 15, 4, 11, 'NOTURNO',  25);


/* =====================================================================
   12. TURMA_HORARIO

   Dois encontros semanais por turma, em terça e quinta.

   O DDL declara a faixa como varchar; o modelo lógico pede timerange,
   que permitiria a restrição EXCLUDE contra sobreposição de sala
   (CA1 da História 4). A carga respeita o DDL atual e grava a faixa em
   notação de intervalo, de modo que a conversão futura seja direta.
   ===================================================================== */
INSERT INTO turma_horario (turma_horario_id, turma_id, sala_id,
                           turma_horario_dia_semana, turma_horario_faixa)
SELECT (t.turma_id - 1) * 2 + e,
       t.turma_id,
       ((t.turma_id - 1) % 15) + 1,
       CASE WHEN e = 1 THEN 2 ELSE 4 END,
       CASE WHEN t.turma_turno = 'MATUTINO'
            THEN '[08:00,09:40)'
            ELSE '[19:00,20:40)' END
  FROM turma t
  CROSS JOIN generate_series(1, 2) AS e;


/* =====================================================================
   13. ALUNO — 120 alunos (mínimo exigido: 100)

   Nomes compostos a partir de arrays de prenomes e sobrenomes,
   combinados por índices diferentes — produz variedade sem tabela
   auxiliar. O CPF é sequencial de 11 dígitos e não corresponde a
   nenhum CPF real.

   Ingressos espalhados por quatro anos, para que a consulta com LAG
   encontre alunos em estágios diferentes do curso.
   ===================================================================== */
INSERT INTO aluno (aluno_id, aluno_matricula, aluno_nome, aluno_cpf,
                   aluno_email, aluno_nascimento, curso_id, curriculo_id,
                   aluno_ingresso, aluno_ativo)
SELECT g,
       '25' || lpad(g::text, 8, '0'),
       (ARRAY['Ana','Bruno','Camila','Daniel','Eduarda','Felipe','Gabriela',
              'Henrique','Isabela','João','Karina','Lucas','Mariana',
              'Nicolas','Olívia','Pedro','Queila','Rafael','Sofia','Thiago',
              'Úrsula','Vinícius','Wesley','Xênia'])[1 + (g - 1) % 24]
       || ' ' ||
       (ARRAY['Almeida','Barbosa','Cardoso','Duarte','Esteves','Ferreira',
              'Gomes','Henriques','Ibrahim','Jardim','Klein','Lima',
              'Moreira','Nogueira','Oliveira','Pereira','Queiroz','Ramos',
              'Santos','Teixeira'])[1 + (g * 7 - 1) % 20],
       lpad((10000000000 + g * 37)::text, 11, '0'),
       'aluno' || lpad(g::text, 4, '0') || '@iesb.edu.br',
       DATE '2000-01-01' + ((g * 97) % 2200),
       CASE WHEN g <=  90 THEN 1
            WHEN g <= 110 THEN 2
            ELSE 3 END,
       CASE WHEN g <=  15 THEN 1      -- currículo 2022 (antigo)
            WHEN g <=  90 THEN 2      -- currículo 2026 de CCO
            WHEN g <= 110 THEN 3      -- Engenharia de Software
            ELSE 4 END,               -- ADS
       DATE '2023-02-01' + ((g % 4) * 182),
       g % 25 <> 0                    -- ~4% inativos
  FROM generate_series(1, 120) AS g;


/* =====================================================================
   14. MATRÍCULA — ~360 (mínimo exigido: 300)

   A distribuição NÃO é uniforme de propósito. Cada aluno se matricula
   em 3 turmas escolhidas por uma função do seu id, o que produz turmas
   com ocupação desigual — algumas perto do limite, outras com folga.
   Distribuição uniforme faria a consulta de vagas devolver o mesmo
   número para todas, sem valor demonstrativo.

   O status varia: a maioria MATRICULADO, alguns TRANCADO e CANCELADO.
   Isso importa porque o CA3 da História 1 estabelece que trancar
   libera vaga — a consulta de ocupação precisa contar só os ativos.
   ===================================================================== */
INSERT INTO matricula (matricula_id, aluno_id, turma_id,
                       matricula_data_matricula, matricula_status)
SELECT row_number() OVER (ORDER BY a.aluno_id, t.turma_id),
       a.aluno_id,
       t.turma_id,
       TIMESTAMPTZ '2026-07-20 08:00:00-03'
         + (a.aluno_id * 7 || ' minutes')::interval,
       CASE
         WHEN (a.aluno_id + t.turma_id) % 23 = 0 THEN 'TRANCADO'
         WHEN (a.aluno_id + t.turma_id) % 31 = 0 THEN 'CANCELADO'
         ELSE 'MATRICULADO'
       END
  FROM aluno a
  JOIN LATERAL (
        -- três turmas por aluno, determinadas pelo id: distribui a
        -- ocupação sem aleatoriedade, mantendo a carga reproduzível
        SELECT DISTINCT t.turma_id
          FROM turma t
         WHERE t.turma_id IN (
                 1 + (a.aluno_id * 3)     % 12,
                 1 + (a.aluno_id * 5 + 1) % 12,
                 1 + (a.aluno_id * 7 + 2) % 12
               )
       ) t ON true
 WHERE a.aluno_ativo;


/* =====================================================================
   15. HISTÓRICO — notas e frequência para as consultas de janela

   Uma linha por matrícula não cancelada. As notas derivam do id por
   uma função pseudo-aleatória determinística, de modo que:

     - a distribuição cobre toda a faixa de 0 a 10;
     - rodar a carga de novo produz exatamente as mesmas notas, e a
       apresentação ao vivo não depende de sorte.

   nota_p3 só existe para quem ficou abaixo da média — é substitutiva
   (CA4 da História 3).

   OBSERVAÇÃO SOBRE TIPOS
   O DDL declara as notas como FLOAT e a frequência como VARCHAR(20).
   O modelo lógico pede nota_t (numeric 4,2) e pct_t. A carga respeita
   o DDL atual e grava a frequência como texto numérico ('87.50'), de
   modo que a conversão nas consultas seja possível. A correção de tipo
   está proposta em 04-ajustes_tipos.sql, para decisão do grupo.
   ===================================================================== */
INSERT INTO historico (historico_id, matricula_id, historico_nota_a1,
                       historico_nota_a2, historico_nota_p3,
                       historico_frequencia, historico_situacao,
                       historico_media_final)
SELECT m.matricula_id,
       m.matricula_id,
       a1.v,
       a2.v,
       CASE WHEN (a1.v + a2.v) / 2 < 6.0
            THEN round((3.0 + ((m.matricula_id * 29) % 70) / 10.0)::numeric, 1)
       END,
       to_char(freq.v, 'FM990.00'),
       CASE
         WHEN freq.v < 75              THEN 'REPROVADO_FALTA'
         WHEN (a1.v + a2.v) / 2 >= 6.0 THEN 'APROVADO'
         ELSE 'REPROVADO_NOTA'
       END,
       round(((a1.v + a2.v) / 2)::numeric, 2)
  FROM matricula m
  CROSS JOIN LATERAL
       (SELECT round((((m.matricula_id * 37) % 101) / 10.0)::numeric, 1)::float AS v) a1
  CROSS JOIN LATERAL
       (SELECT round((((m.matricula_id * 53) % 101) / 10.0)::numeric, 1)::float AS v) a2
  CROSS JOIN LATERAL
       (SELECT round((60 + ((m.matricula_id * 17) % 41))::numeric, 2) AS v) freq
 WHERE m.matricula_status <> 'CANCELADO';


/* =====================================================================
   16. LOG_MATRICULA

   Uma linha de INSERT por matrícula criada, como o requisito R10 prevê.
   Usuário e instante vêm do servidor (CURRENT_USER, now()), não da
   aplicação — é o que o CA2 da História 7 exige.
   ===================================================================== */
INSERT INTO log_matricula (log_matricula_id, matricula_id,
                           log_matricula_acao, log_matricula_ocorrido_em,
                           log_matricula_usuario, log_matricula_detalhe)
SELECT m.matricula_id,
       m.matricula_id,
       'INSERT',
       m.matricula_data_matricula,
       CURRENT_USER,
       jsonb_build_object(
         'aluno_id', m.aluno_id,
         'turma_id', m.turma_id,
         'status',   m.matricula_status,
         'origem',   'carga_inicial')
  FROM matricula m;

-- Linhas de UPDATE para quem trancou ou cancelou: o log registra a
-- mudança de status, não apenas a criação.
INSERT INTO log_matricula (log_matricula_id, matricula_id,
                           log_matricula_acao, log_matricula_ocorrido_em,
                           log_matricula_usuario, log_matricula_detalhe)
SELECT 100000 + m.matricula_id,
       m.matricula_id,
       'UPDATE',
       m.matricula_data_matricula + interval '45 days',
       CURRENT_USER,
       jsonb_build_object(
         'de',     'MATRICULADO',
         'para',   m.matricula_status,
         'motivo', CASE m.matricula_status
                     WHEN 'TRANCADO'  THEN 'solicitacao_do_aluno'
                     WHEN 'CANCELADO' THEN 'inadimplencia'
                   END)
  FROM matricula m
 WHERE m.matricula_status IN ('TRANCADO', 'CANCELADO');

COMMIT;


/* =====================================================================
   CONFERÊNCIA DA CARGA

   Confronta o inserido com o mínimo exigido pelo enunciado (seção 4.1).
   Todas as linhas devem marcar OK.
   ===================================================================== */
SELECT 'alunos' AS entidade, count(*) AS inseridos, 100 AS minimo,
       CASE WHEN count(*) >= 100 THEN 'OK' ELSE 'ABAIXO' END AS situacao
  FROM aluno
UNION ALL
SELECT 'turmas',         count(*),   6,
       CASE WHEN count(*) >=   6 THEN 'OK' ELSE 'ABAIXO' END FROM turma
UNION ALL
SELECT 'matriculas',     count(*), 300,
       CASE WHEN count(*) >= 300 THEN 'OK' ELSE 'ABAIXO' END FROM matricula
UNION ALL
SELECT 'historicos',     count(*),   0, 'OK' FROM historico
UNION ALL
SELECT 'disciplinas',    count(*),   0, 'OK' FROM disciplina
UNION ALL
SELECT 'pre_requisitos', count(*),   0, 'OK' FROM pre_requisito;
