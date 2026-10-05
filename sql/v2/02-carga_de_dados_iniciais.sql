/* =====================================================================
   PROJETO: Sistema de Matrícula Acadêmica
   DISCIPLINA: Banco de Dados II (CCO072) — IESB 2026/2
   PROFESSOR: Rodrigo Gonçalves

   ARQUIVO: 02-carga_de_dados_iniciais.sql
   DESCRIÇÃO: Povoamento do esquema "academico" (DDL v2, com auditoria).

   PRÉ-REQUISITO: executar antes o 01 (DDL v2).

   O QUE ESTA CARGA GARANTE
     - Mínimo do enunciado: 100 alunos, 6 turmas, 300 matrículas.
     - Todas as 33 tabelas com dados, para que nenhuma consulta rode
       sobre tabela vazia.
     - Dados determinísticos: os valores "aleatórios" saem de aritmética
       modular sobre o índice. Rodar duas vezes dá o mesmo resultado, e
       qualquer integrante do grupo reproduz o mesmo banco.
     - Nenhuma turma passa do limite de vagas.
     - Nenhuma sala recebe duas turmas no mesmo dia e horário (o EXCLUDE
       da tabela tb_turma_horario recusaria).
     - A data de referência é 05/10/2026 (fixa, não CURRENT_DATE), para
       que aulas realizadas e notas lançadas não mudem com o dia em que o
       script roda.

   IDEMPOTÊNCIA: o TRUNCATE ... RESTART IDENTITY do início zera as tabelas
   e os contadores IDENTITY. Assim os ids gerados são sempre 1, 2, 3...
   na ordem de inserção, e as referências abaixo podem contar com eles.

   AUDITORIA: os gatilhos do DDL registram cada INSERT em
   tb_log_auditoria. Ao final da carga, o log já tem o rastro completo.
   ===================================================================== */

SET search_path TO academico, public;

TRUNCATE tb_log_auditoria, tb_requerimento, tb_mensalidade, tb_aluno_bolsa,
         tb_bolsa_desconto, tb_atividade_complementar, tb_nota_avaliacao,
         tb_avaliacao, tb_chamada, tb_historico, tb_matricula, tb_aula,
         tb_turma_horario, tb_turma, tb_calendario_academico,
         tb_periodo_letivo, tb_aproveitamento_disciplina, tb_pre_requisito,
         tb_curriculo_disciplina, tb_disciplina, tb_ementa, tb_aluno,
         tb_curriculo, tb_curso, tb_professor, tb_funcionario, tb_pessoa,
         tb_inventario_sala, tb_sala, tb_campus, tb_cidade, tb_estado, tb_pais
RESTART IDENTITY CASCADE;


/* ---------------------------------------------------------------------
   1. GEOGRAFIA E ESTRUTURA FÍSICA
   --------------------------------------------------------------------- */
INSERT INTO tb_pais (nome_pais, sigla_pais) VALUES
  ('Brasil', 'BR'),
  ('Portugal', 'PT');

INSERT INTO tb_estado (nome_estado, sigla_estado, pais_id_estado) VALUES
  ('Distrito Federal', 'DF', 1),
  ('Goiás',            'GO', 1),
  ('São Paulo',        'SP', 1),
  ('Lisboa',           'LX', 2);

INSERT INTO tb_cidade (nome_cidade, estado_id_cidade) VALUES
  ('Brasília', 1), ('Taguatinga', 1), ('Ceilândia', 1),
  ('Goiânia', 2), ('Águas Lindas de Goiás', 2),
  ('São Paulo', 3), ('Lisboa', 4);

INSERT INTO tb_campus (nome_campus, cidade_id_campus) VALUES
  ('Asa Sul',   1),
  ('Asa Norte', 1),
  ('Ceilândia', 3);

-- Código de sala no padrão do portal: P + bloco + número (PIA2, PJB1).
INSERT INTO tb_sala (campus_id_sala, codigo_sala, capacidade_sala, tipo_sala) VALUES
  (1, 'PIA1', 50, 'TEORICA'),     (1, 'PIA2', 50, 'TEORICA'),
  (1, 'PJB1', 50, 'TEORICA'),     (1, 'PJB5', 45, 'TEORICA'),
  (1, 'PIL1', 40, 'LABORATORIO'), (1, 'PIL2', 40, 'LABORATORIO'),
  (1, 'AUD1', 200, 'AUDITORIO'),  (2, 'NA101', 45, 'TEORICA'),
  (2, 'NAL01', 35, 'LABORATORIO'),(3, 'CE101', 45, 'TEORICA');

INSERT INTO tb_inventario_sala (sala_id_inventario_sala, nome_item_inventario_sala,
       patrimonio_inventario_sala, quantidade_inventario_sala,
       estado_conservacao_inventario_sala, ultima_vistoria_inventario_sala)
SELECT s.id_sala, item.nome,
       format('IESB-%s-%s', s.codigo_sala, item.sufixo),
       item.qtd,
       (ARRAY['BOM','BOM','REGULAR','RUIM']::tipo_invent_t[])[1 + (s.id_sala + item.ord) % 4],
       DATE '2026-07-01' + (s.id_sala * 3 + item.ord)
  FROM tb_sala s
 CROSS JOIN (VALUES (1, 'Projetor multimídia', 'PRJ', 1),
                    (2, 'Ar-condicionado',     'ARC', 2),
                    (3, 'Quadro branco',       'QDB', 1)) AS item(ord, nome, sufixo, qtd);


/* ---------------------------------------------------------------------
   2. PESSOAS
   Pessoas 1 a 120 são alunos; 121 a 132, professores; 133 a 136,
   funcionários administrativos.
   --------------------------------------------------------------------- */
INSERT INTO tb_pessoa (nome_pessoa, cpf_pessoa, email_pessoa, telefone_pessoa,
                       nascimento_pessoa, cidade_id_pessoa)
SELECT nome,
       to_char(30000000000 + i * 104729, 'FM00000000000'),
       lower(translate(split_part(nome, ' ', 1) || '.' || split_part(nome, ' ', 2),
                       'áéíóúãõâêôçÁÉÍÓÚÃÕÂÊÔÇÚ', 'aeiouaoaeocAEIOUAOAEOCU'))
         || i || '@iesb.edu.br',
       format('(61) 9%s-%s', 8000 + (i * 37) % 2000, 1000 + (i * 91) % 9000),
       DATE '1994-01-01' + (i * 97) % 3650,
       1 + i % 6
  FROM (
    SELECT i,
           (ARRAY['Ana','Bruno','Carla','Daniel','Eduarda','Felipe','Gabriela','Henrique',
                  'Isabela','João','Karen','Lucas','Mariana','Nicolas','Olívia','Pedro',
                  'Raquel','Rafael','Sofia','Thiago','Valéria','Vinícius','Yasmin','Wesley'])[1 + i % 24]
           || ' ' ||
           (ARRAY['Silva','Santos','Oliveira','Souza','Lima','Pereira','Costa','Rodrigues',
                  'Almeida','Nascimento','Carvalho','Ferreira','Gomes','Ribeiro','Martins','Araújo'])[1 + (i * 7) % 16]
           || ' ' ||
           (ARRAY['Barbosa','Rocha','Dias','Teixeira','Moreira','Cardoso','Mendes','Freitas',
                  'Batista','Pinto','Vieira','Monteiro','Campos','Moura','Correia','Lopes'])[1 + (i * 11 + 3) % 16] AS nome
      FROM generate_series(1, 120) AS i
  ) alunos;

INSERT INTO tb_pessoa (nome_pessoa, cpf_pessoa, email_pessoa, telefone_pessoa,
                       nascimento_pessoa, cidade_id_pessoa)
SELECT p.nome,
       to_char(70000000000 + p.n * 7331, 'FM00000000000'),
       p.email, format('(61) 3%s-%s', 300 + p.n, 1000 + p.n * 37),
       p.nasc, 1
  FROM (VALUES
    ( 1, 'Helena Prado Castilho',      'helena.castilho@iesb.edu.br',   DATE '1978-03-14'),
    ( 2, 'Otávio Reis Bittencourt',    'otavio.bittencourt@iesb.edu.br',DATE '1981-07-02'),
    ( 3, 'Cecília Amaral Fontes',      'cecilia.fontes@iesb.edu.br',    DATE '1975-11-23'),
    ( 4, 'Gustavo Leme Paranhos',      'gustavo.paranhos@iesb.edu.br',  DATE '1983-01-30'),
    ( 5, 'Lívia Torres Mascarenhas',   'livia.mascarenhas@iesb.edu.br', DATE '1986-05-19'),
    ( 6, 'Rodrigo Albuquerque Sena',   'rodrigo.sena@iesb.edu.br',      DATE '1979-09-08'),
    ( 7, 'Beatriz Fontoura Lacerda',   'beatriz.lacerda@iesb.edu.br',   DATE '1984-12-01'),
    ( 8, 'Marcelo Quintela Duarte',    'marcelo.duarte@iesb.edu.br',    DATE '1972-04-17'),
    ( 9, 'Patrícia Valadares Coelho',  'patricia.coelho@iesb.edu.br',   DATE '1980-08-26'),
    (10, 'Renato Siqueira Brandão',    'renato.brandao@iesb.edu.br',    DATE '1977-02-11'),
    (11, 'Tânia Medeiros Guimarães',   'tania.guimaraes@iesb.edu.br',   DATE '1982-06-05'),
    (12, 'Fábio Cordeiro Nogueira',    'fabio.nogueira@iesb.edu.br',    DATE '1988-10-21'),
    (13, 'Sandra Ferraz Peixoto',      'sandra.peixoto@iesb.edu.br',    DATE '1985-03-09'),
    (14, 'Jorge Antunes Salgado',      'jorge.salgado@iesb.edu.br',     DATE '1990-01-15'),
    (15, 'Denise Rangel Pacheco',      'denise.pacheco@iesb.edu.br',    DATE '1987-07-28'),
    (16, 'Caio Bastos Figueira',       'caio.figueira@iesb.edu.br',     DATE '1993-12-12')
  ) AS p(n, nome, email, nasc)
 ORDER BY p.n;

-- Funcionários: os 12 primeiros são professores (ids 1 a 12).
INSERT INTO tb_funcionario (pessoa_id_funcionario, matricula_funcionario,
                            cargo_funcionario, data_contratacao_funcionario, ativo_funcionario)
SELECT 120 + n,
       format('F%s', 20000 + n),
       CASE WHEN n <= 12 THEN 'Professor'
            WHEN n = 13  THEN 'Secretária acadêmica'
            WHEN n = 14  THEN 'Analista de registro acadêmico'
            WHEN n = 15  THEN 'Coordenadora de curso'
            ELSE 'Assistente financeiro' END,
       DATE '2010-02-01' + n * 211,
       TRUE
  FROM generate_series(1, 16) AS n;

INSERT INTO tb_professor (funcionario_id_professor, titulacao_professor)
SELECT n, (ARRAY['DOUTOR','MESTRE','MESTRE','DOUTOR','ESPECIALISTA','POS_DOUTOR']::tipo_titulacao_t[])[1 + n % 6]
  FROM generate_series(1, 12) AS n;


/* ---------------------------------------------------------------------
   3. ESTRUTURA ACADÊMICA
   --------------------------------------------------------------------- */
INSERT INTO tb_curso (codigo_curso, nome_curso, grau_curso, campus_id_curso) VALUES
  ('2130', 'Ciência da Computação',   'BACHARELADO',  1),
  ('2140', 'Engenharia de Software',  'BACHARELADO',  1),
  ('2310', 'Matemática',              'LICENCIATURA', 1);

-- Um currículo vigente por curso (índice único parcial uq_curriculo_ativo).
-- CCO tem duas versões: 2020 (encerrada) e 2023 (vigente).
INSERT INTO tb_curriculo (curso_id_curriculo, ano_vigencia_curriculo,
                          ch_total_exigida_curriculo, ativo_curriculo) VALUES
  (1, 2020, 3580, FALSE),
  (1, 2023, 3300, TRUE),
  (2, 2024, 3200, TRUE),
  (3, 2024, 3240, TRUE);

INSERT INTO tb_ementa (objetivo_ementa, conteudo_programatico_ementa,
                       bibliografia_basica_ementa, bibliografia_complementar_ementa) VALUES
  ('Desenvolver o raciocínio algorítmico e a programação estruturada.',
   'Variáveis, tipos, estruturas de decisão e repetição, vetores, funções.',
   'FORBELLONE, A. L. V. Lógica de programação. 3. ed. Pearson, 2005.', NULL),
  ('Projetar e otimizar bancos de dados relacionais em PostgreSQL.',
   'SQL avançado, consultas recursivas, funções de janela, índices, transações, concorrência, segurança.',
   'SILBERSCHATZ, A.; KORTH, H.; SUDARSHAN, S. Sistema de banco de dados. 7. ed. LTC, 2020.',
   'ELMASRI, R.; NAVATHE, S. Sistemas de banco de dados. 7. ed. Pearson, 2018.'),
  ('Formular problemas como busca e como aprendizado a partir de dados.',
   'Agentes, busca heurística, aprendizado supervisionado e não supervisionado, redes neurais, LLMs.',
   'RUSSELL, S.; NORVIG, P. Artificial intelligence: a modern approach. 4. ed. Pearson, 2021.',
   'GÉRON, A. Mãos à obra: aprendizado de máquina. 2. ed. Alta Books, 2021.'),
  ('Aplicar os princípios da orientação a objetos em Java.',
   'Classes, encapsulamento, herança, polimorfismo, interfaces, coleções, exceções.',
   'DEITEL, P.; DEITEL, H. Java: como programar. 10. ed. Pearson, 2016.', NULL);

-- Disciplinas da matriz de Ciência da Computação. A ordem define o id (1 a 20).
INSERT INTO tb_disciplina (codigo_disciplina, nome_disciplina,
                           ch_teorica_disciplina, ch_pratica_disciplina, ementa_id_disciplina) VALUES
  ('MDC118',  'Algoritmos e Programação de Computadores I',  30, 30, 1),   --  1
  ('MDC119',  'Algoritmos e Programação de Computadores II', 30, 30, NULL),--  2
  ('MDC101',  'Cálculo I',                                   45, 15, NULL),--  3
  ('MDC102',  'Cálculo II',                                  45, 15, NULL),--  4
  ('MDC105',  'Fundamentos de Lógica',                       45, 15, NULL),--  5
  ('MDC106',  'Álgebra Linear',                              45, 15, NULL),--  6
  ('MDC107',  'Geometria Analítica e Vetores',               45, 15, NULL),--  7
  ('CCO071',  'Banco de Dados I',                            30, 30, NULL),--  8
  ('CCO072',  'Banco de Dados II',                           30, 30, 2),   --  9
  ('MDC120',  'Estrutura de Dados',                          15, 45, NULL),-- 10
  ('MDC121',  'Programação Orientada a Objetos',             15, 45, 4),   -- 11
  ('MDC122',  'Sistemas Operacionais',                       45, 15, NULL),-- 12
  ('HMDC073', 'Engenharia de Software',                      45, 15, NULL),-- 13
  ('MDC050',  'Inteligência Artificial',                     45, 15, 3),   -- 14
  ('HMDC250', 'Governança de TI e Mapeamento de Processos',  60,  0, NULL),-- 15
  ('MDC130',  'Teoria dos Grafos',                           30, 30, NULL),-- 16
  ('MDC131',  'Cálculo Numérico',                            30, 30, NULL),-- 17
  ('MDC140',  'Compiladores',                                45, 15, NULL),-- 18
  ('MDC150',  'Interface Homem-Computador',                  30, 30, NULL),-- 19
  ('MDC151',  'Libras',                                      30, 30, NULL);-- 20

INSERT INTO tb_curriculo_disciplina (curriculo_id_curriculo_disciplina,
       disciplina_id_curriculo_disciplina, periodo_curriculo_disciplina, tipo_curriculo_disciplina)
SELECT c, d, p, t::tipo_disc_t
  FROM (VALUES
    -- CCO 2023 (currículo 2, vigente)
    (2, 1,1,'OBRIGATORIA'),(2, 3,1,'OBRIGATORIA'),(2, 5,1,'OBRIGATORIA'),(2, 7,1,'OBRIGATORIA'),
    (2, 2,2,'OBRIGATORIA'),(2, 4,2,'OBRIGATORIA'),(2, 6,2,'OBRIGATORIA'),(2, 8,2,'OBRIGATORIA'),
    (2, 9,3,'OBRIGATORIA'),(2,10,3,'OBRIGATORIA'),(2,11,3,'OBRIGATORIA'),
    (2,12,4,'OBRIGATORIA'),(2,13,4,'OBRIGATORIA'),(2,14,4,'OBRIGATORIA'),(2,15,4,'OBRIGATORIA'),
    (2,16,5,'OBRIGATORIA'),(2,17,5,'OBRIGATORIA'),(2,18,6,'OBRIGATORIA'),
    (2,19,7,'ELETIVA'),(2,20,7,'ELETIVA'),
    -- CCO 2020 (currículo 1, encerrado): sem Eng. Software nem Governança
    (1, 1,1,'OBRIGATORIA'),(1, 3,1,'OBRIGATORIA'),(1, 5,1,'OBRIGATORIA'),(1, 7,1,'OBRIGATORIA'),
    (1, 2,2,'OBRIGATORIA'),(1, 4,2,'OBRIGATORIA'),(1, 6,2,'OBRIGATORIA'),(1, 8,2,'OBRIGATORIA'),
    (1, 9,3,'OBRIGATORIA'),(1,10,3,'OBRIGATORIA'),(1,11,3,'OBRIGATORIA'),(1,12,4,'OBRIGATORIA'),
    (1,14,4,'OBRIGATORIA'),(1,16,5,'OBRIGATORIA'),(1,17,5,'OBRIGATORIA'),(1,18,6,'OBRIGATORIA'),
    (1,19,7,'OPTATIVA'),
    -- Engenharia de Software 2024 (currículo 3)
    (3, 1,1,'OBRIGATORIA'),(3, 5,1,'OBRIGATORIA'),(3, 2,2,'OBRIGATORIA'),(3, 8,2,'OBRIGATORIA'),
    (3,10,3,'OBRIGATORIA'),(3,11,3,'OBRIGATORIA'),(3,13,3,'OBRIGATORIA'),(3, 9,4,'OBRIGATORIA'),
    (3,15,4,'OBRIGATORIA'),(3,14,5,'OPTATIVA'),(3,19,5,'OBRIGATORIA'),
    -- Matemática 2024 (currículo 4)
    (4, 3,1,'OBRIGATORIA'),(4, 7,1,'OBRIGATORIA'),(4, 4,2,'OBRIGATORIA'),(4, 6,2,'OBRIGATORIA'),
    (4,17,3,'OBRIGATORIA'),(4,16,4,'OPTATIVA'),(4,20,4,'OBRIGATORIA')
  ) AS v(c, d, p, t);

-- Grafo de pré-requisitos. A cadeia 1 > 2 > 10 > 16 > 18 tem quatro níveis,
-- material para a consulta recursiva. Álgebra Linear e Geometria Analítica
-- são co-requisitos: cursadas juntas, não uma antes da outra.
INSERT INTO tb_pre_requisito (disciplina_id_pre_requisito, requisito_id_pre_requisito,
                              vinculo_pre_requisito) VALUES
  ( 2,  1, 'PRE_REQUISITO'),   -- APC II exige APC I
  ( 4,  3, 'PRE_REQUISITO'),   -- Cálculo II exige Cálculo I
  ( 8,  5, 'PRE_REQUISITO'),   -- BD I exige Fundamentos de Lógica
  ( 9,  8, 'PRE_REQUISITO'),   -- BD II exige BD I
  (10,  2, 'PRE_REQUISITO'),   -- Estrutura de Dados exige APC II
  (11,  2, 'PRE_REQUISITO'),   -- POO exige APC II
  (12, 10, 'PRE_REQUISITO'),   -- SO exige Estrutura de Dados
  (14,  2, 'PRE_REQUISITO'),   -- IA exige APC II (plano de ensino)
  (16, 10, 'PRE_REQUISITO'),   -- Grafos exige Estrutura de Dados
  (17,  4, 'PRE_REQUISITO'),   -- Cálculo Numérico exige Cálculo II
  (17,  6, 'PRE_REQUISITO'),   -- Cálculo Numérico exige Álgebra Linear
  (18, 16, 'PRE_REQUISITO'),   -- Compiladores exige Grafos
  ( 6,  7, 'CO_REQUISITO');    -- Álgebra Linear junto com Geometria Analítica


/* ---------------------------------------------------------------------
   4. ALUNOS
   RA no padrão do portal: ano de ingresso (2) + código do curso (4) +
   sequência (4). Distribuição: 70% CCO 2023, 5% CCO 2020, 15% Eng.
   Software, 10% Matemática. Os alunos 117 a 120 têm vínculo encerrado.
   --------------------------------------------------------------------- */
INSERT INTO tb_aluno (pessoa_id_aluno, matricula_aluno, curriculo_id_aluno,
                      ingresso_aluno, status_detalhado_aluno)
SELECT i,
       to_char(ing, 'YY') || cur.codigo || lpad(i::text, 4, '0'),
       cur.id,
       ing,
       CASE i WHEN 117 THEN 'TRANCADO' WHEN 118 THEN 'CANCELADO'
              WHEN 119 THEN 'FORMADO'  WHEN 120 THEN 'JUBILADO'
              ELSE 'ATIVO' END::tipo_status_t
  FROM generate_series(1, 120) AS i
 CROSS JOIN LATERAL (
   SELECT CASE WHEN i % 20 = 0 THEN 1
               WHEN i % 10 < 7 THEN 2
               WHEN i % 10 < 9 THEN 3
               ELSE 4 END AS id
 ) c
 CROSS JOIN LATERAL (
   SELECT c.id, CASE c.id WHEN 3 THEN '2140' WHEN 4 THEN '2310' ELSE '2130' END AS codigo
 ) cur
 CROSS JOIN LATERAL (
   SELECT CASE WHEN c.id = 1 THEN DATE '2021-02-01'
               ELSE (ARRAY[DATE '2024-02-05', DATE '2024-08-05', DATE '2025-02-03', DATE '2025-08-04'])[1 + i % 4]
          END AS ing
 ) d;

INSERT INTO tb_aproveitamento_disciplina (aluno_id_aproveitamento_disciplina,
       disciplina_id_aproveitamento_disciplina, instituicao_origem_aproveitamento_disciplina,
       ch_aprovada_aproveitamento_disciplina, nota_origem_aproveitamento_disciplina,
       status_aprovacao_aproveitamento_disciplina, observacao_aproveitamento_disciplina) VALUES
  ( 4, 3, 'Universidade de Brasília',          60, 8.20, 'DEFERIDO',   'Ementa equivalente.'),
  ( 4, 5, 'Universidade de Brasília',          60, 7.50, 'DEFERIDO',   NULL),
  (15, 1, 'Instituto Federal de Brasília',     60, 6.80, 'DEFERIDO',   NULL),
  (27, 7, 'Universidade Católica de Brasília', 45, 7.00, 'INDEFERIDO', 'Carga horária inferior à exigida (60h).'),
  (33, 3, 'Universidade Federal de Goiás',     60, 9.10, 'EM_ANALISE', 'Aguardando plano de ensino de origem.'),
  (48, 6, 'Universidade Paulista',             60, 5.90, 'EM_ANALISE', NULL);


/* ---------------------------------------------------------------------
   5. CALENDÁRIO
   --------------------------------------------------------------------- */
INSERT INTO tb_periodo_letivo (ano_periodo_letivo, semestre_periodo_letivo,
       bimestre_periodo_letivo, data_inicio_periodo_letivo, data_fim_periodo_letivo) VALUES
  (2025, 1, NULL, DATE '2025-02-03', DATE '2025-06-28'),   -- 1
  (2025, 2, NULL, DATE '2025-08-04', DATE '2025-12-13'),   -- 2
  (2026, 1, NULL, DATE '2026-02-02', DATE '2026-06-27'),   -- 3
  (2026, 2, NULL, DATE '2026-08-03', DATE '2026-12-12');   -- 4

INSERT INTO tb_calendario_academico (periodo_letivo_id_calendario_academico,
       data_evento_calendario_academico, tipo_evento_calendario_academico,
       descricao_calendario_academico, campus_id_calendario_academico) VALUES
  (4, DATE '2026-08-03', 'OUTRO',           'Início das aulas do 2º semestre',  NULL),
  (4, DATE '2026-08-14', 'PRAZO_MATRICULA', 'Fim do ajuste de matrícula',      1),
  (4, DATE '2026-09-07', 'FERIADO',         'Independência do Brasil',         NULL),
  (4, DATE '2026-09-23', 'AVALIACAO',       'Semana de provas P1',             1),
  (4, DATE '2026-10-12', 'FERIADO',         'Nossa Senhora Aparecida',         NULL),
  (4, DATE '2026-10-28', 'OUTRO',           'Dia do Servidor Público (ponto facultativo)', 1),
  (4, DATE '2026-11-02', 'FERIADO',         'Finados',                         NULL),
  (4, DATE '2026-11-20', 'FERIADO',         'Dia da Consciência Negra',        NULL),
  (4, DATE '2026-11-25', 'AVALIACAO',       'Semana de provas P2',             1),
  (4, DATE '2026-12-09', 'AVALIACAO',       'Prova substitutiva P3',           1),
  (3, DATE '2026-04-21', 'FERIADO',         'Tiradentes',                      NULL),
  (3, DATE '2026-06-04', 'FERIADO',         'Corpus Christi',                  NULL);


/* ---------------------------------------------------------------------
   6. TURMAS E HORÁRIOS
   Turmas 1 a 6: 2026/1 (concluídas). Turmas 7 a 16: 2026/2 (em curso).
   --------------------------------------------------------------------- */
INSERT INTO tb_turma (codigo_turma, disciplina_id_turma, periodo_letivo_id_turma,
                      professor_id_turma, turno_turma, vagas_turma) VALUES
  ('CCONM1A',   1, 3,  1, 'NOTURNO', 35),   --  1  APC I
  ('CCONM1A',   3, 3,  2, 'NOTURNO', 35),   --  2  Cálculo I
  ('CCONM1A',   5, 3,  3, 'NOTURNO', 35),   --  3  Fund. Lógica
  ('CCONM1A',   7, 3,  4, 'NOTURNO', 35),   --  4  Geometria
  ('CCONM1B',   2, 3,  1, 'NOTURNO', 35),   --  5  APC II
  ('CCONM1B',   8, 3,  5, 'NOTURNO', 35),   --  6  BD I
  ('CCONM2B',   9, 4,  6, 'NOTURNO', 45),   --  7  BD II
  ('ENGCNM2B', 14, 4,  6, 'NOTURNO', 45),   --  8  IA
  ('ENGCNM2B', 13, 4,  7, 'NOTURNO', 45),   --  9  Eng. Software
  ('ENGCNM2B', 11, 4,  8, 'NOTURNO', 40),   -- 10  POO
  ('ENGCNM3B', 12, 4,  9, 'NOTURNO', 40),   -- 11  SO
  ('CCONM2B',  15, 4,  9, 'NOTURNO', 45),   -- 12  Governança
  ('CCONM2A',  10, 4, 10, 'NOTURNO', 40),   -- 13  Estrutura de Dados
  ('CCONM2A',   4, 4,  2, 'NOTURNO', 40),   -- 14  Cálculo II
  ('CCONM3B',  16, 4, 11, 'NOTURNO', 40),   -- 15  Grafos
  ('CCONM3A',  17, 4, 12, 'NOTURNO', 40);   -- 16  Cálculo Numérico

-- Dois encontros na mesma noite e sala, como no portal: 19:15-20:30 e
-- 20:45-22:00. Cada turma recebe um par (sala, dia) exclusivo, e nenhum
-- professor tem duas turmas na mesma noite do mesmo período: os dois
-- EXCLUDE do DDL (sala e professor) recusariam.
-- Período e professor são copiados da turma; as FKs compostas do DDL
-- garantem que batem.
-- dia_semana: 1 = domingo ... 7 = sábado.
INSERT INTO tb_turma_horario (turma_id_turma_horario, sala_id_turma_horario,
       dia_semana_turma_horario, faixa_turma_horario, modalidade_turma_horario,
       periodo_letivo_id_turma_horario, professor_id_turma_horario)
SELECT t.id_turma,
       1 + (t.id_turma - 1) / 5,
       2 + (t.id_turma - 1) % 5,
       f.faixa,
       CASE WHEN t.disciplina_id_turma = 15 THEN 'EAD' ELSE 'PRESENCIAL' END::tipo_turma_t,
       t.periodo_letivo_id_turma,
       t.professor_id_turma
  FROM tb_turma t
 CROSS JOIN (VALUES (timerange('19:15', '20:30', '[)')),
                    (timerange('20:45', '22:00', '[)'))) AS f(faixa);

-- Aulas de 2026/2, uma por encontro e semana, pulando feriados.
-- Até 05/10/2026 estão realizadas; daí em diante, agendadas.
INSERT INTO tb_aula (turma_horario_id_aula, data_aula, conteudo_previsto_aula,
                     conteudo_realizado_aula, status_aula)
SELECT h.id_turma_horario,
       d::date,
       format('Aula %s de %s', row_number() OVER (PARTITION BY h.id_turma_horario ORDER BY d), di.nome_disciplina),
       CASE WHEN d::date < DATE '2026-10-05' THEN 'Conteúdo previsto ministrado.' END,
       CASE WHEN d::date < DATE '2026-10-05' THEN 'REALIZADA' ELSE 'AGENDADA' END::tipo_aula_t
  FROM tb_turma_horario h
  JOIN tb_turma t       ON t.id_turma = h.turma_id_turma_horario
  JOIN tb_disciplina di ON di.id_disciplina = t.disciplina_id_turma
 CROSS JOIN generate_series(DATE '2026-08-03', DATE '2026-12-04', INTERVAL '1 day') AS d
 WHERE t.periodo_letivo_id_turma = 4
   AND extract(dow FROM d) + 1 = h.dia_semana_turma_horario
   AND NOT EXISTS (SELECT 1 FROM tb_calendario_academico c
                    WHERE c.data_evento_calendario_academico = d::date
                      AND c.tipo_evento_calendario_academico = 'FERIADO');


/* ---------------------------------------------------------------------
   7. MATRÍCULAS
   2026/1: alunos 1 a 80, duas turmas cada, status CONCLUIDO.
   2026/2: alunos ativos 1 a 116, três turmas cada. O deslocamento de
   3 em 3 sobre as dez turmas nunca repete turma para o mesmo aluno
   (chave única aluno-turma) e espalha ~35 alunos por turma, abaixo das
   40 a 45 vagas.
   --------------------------------------------------------------------- */
INSERT INTO tb_matricula (aluno_id_matricula, turma_id_matricula, data_matricula, status_matricula)
SELECT a, 1 + ((a + k * 3) % 6),
       TIMESTAMPTZ '2026-01-26 10:00-03' + make_interval(mins => a * 7 + k),
       'CONCLUIDO'
  FROM generate_series(1, 80) AS a, generate_series(0, 1) AS k;

INSERT INTO tb_matricula (aluno_id_matricula, turma_id_matricula, data_matricula, status_matricula)
SELECT a, 7 + ((a + k * 3) % 10),
       TIMESTAMPTZ '2026-07-27 09:00-03' + make_interval(mins => a * 11 + k),
       CASE WHEN k = 0 AND a % 17 = 0 THEN 'TRANCADO'
            WHEN k = 1 AND a % 23 = 0 THEN 'CANCELADO'
            ELSE 'MATRICULADO' END::status_mat_t
  FROM generate_series(1, 116) AS a, generate_series(0, 2) AS k;


/* ---------------------------------------------------------------------
   8. AVALIAÇÕES, NOTAS, CHAMADA E HISTÓRICO
   Pesos do plano de ensino: A1 = 40%, A2 = 60%. Em 2026/2 só a A1
   aconteceu (23/09); a A2 está agendada para 25/11.
   --------------------------------------------------------------------- */
INSERT INTO tb_avaliacao (turma_id_avaliacao, titulo_avaliacao, peso_avaliacao, data_avaliacao)
SELECT t.id_turma, a.titulo, a.peso,
       CASE WHEN t.periodo_letivo_id_turma = 3 THEN a.data_s1 ELSE a.data_s2 END
  FROM tb_turma t
 CROSS JOIN (VALUES ('A1', 0.40, DATE '2026-04-08', DATE '2026-09-23'),
                    ('A2', 0.60, DATE '2026-06-17', DATE '2026-11-25')) AS a(titulo, peso, data_s1, data_s2);

-- Nota determinística entre 3,0 e 10,0. Trancados e cancelados não fazem prova.
INSERT INTO tb_nota_avaliacao (avaliacao_id_nota_avaliacao, matricula_id_nota_avaliacao, nota_nota_avaliacao)
SELECT av.id_avaliacao, m.id_matricula,
       round(3 + ((m.aluno_id_matricula * CASE av.titulo_avaliacao WHEN 'A1' THEN 37 ELSE 53 END
                  + m.turma_id_matricula * 11) % 71) / 10.0, 1)
  FROM tb_matricula m
  JOIN tb_avaliacao av ON av.turma_id_avaliacao = m.turma_id_matricula
 WHERE m.status_matricula IN ('CONCLUIDO', 'MATRICULADO')
   AND av.data_avaliacao < DATE '2026-10-05';

-- Chamada das aulas realizadas. Cerca de 1 falta a cada 9 presenças,
-- concentrada em alguns alunos para produzir reprovação por frequência.
INSERT INTO tb_chamada (aula_id_chamada, matricula_id_chamada, presente_chamada, justificativa_chamada)
SELECT au.id_aula, m.id_matricula,
       NOT ((m.aluno_id_matricula * 13 + au.id_aula * 7) % 9 = 0
            OR (m.aluno_id_matricula % 19 = 0 AND au.id_aula % 3 = 0)),
       CASE WHEN (m.aluno_id_matricula * 13 + au.id_aula * 7) % 45 = 0 THEN 'Atestado médico' END
  FROM tb_aula au
  JOIN tb_turma_horario h ON h.id_turma_horario = au.turma_horario_id_aula
  JOIN tb_matricula m     ON m.turma_id_matricula = h.turma_id_turma_horario
 WHERE au.status_aula = 'REALIZADA'
   AND m.status_matricula = 'MATRICULADO';

-- Histórico: um por matrícula. As notas vêm das avaliações lançadas e a
-- média é a coluna gerada do DDL — não é escrita aqui.
INSERT INTO tb_historico (matricula_id_historico, nota_a1_historico, nota_a2_historico,
                          nota_p3_historico, frequencia_historico)
SELECT m.id_matricula,
       (SELECT n.nota_nota_avaliacao FROM tb_nota_avaliacao n JOIN tb_avaliacao a ON a.id_avaliacao = n.avaliacao_id_nota_avaliacao
         WHERE n.matricula_id_nota_avaliacao = m.id_matricula AND a.titulo_avaliacao = 'A1'),
       (SELECT n.nota_nota_avaliacao FROM tb_nota_avaliacao n JOIN tb_avaliacao a ON a.id_avaliacao = n.avaliacao_id_nota_avaliacao
         WHERE n.matricula_id_nota_avaliacao = m.id_matricula AND a.titulo_avaliacao = 'A2'),
       NULL,
       CASE WHEN m.status_matricula = 'CONCLUIDO'
            THEN 72 + (m.aluno_id_matricula * 7 + m.turma_id_matricula * 3) % 29
            ELSE 100 END
  FROM tb_matricula m;

-- Frequência de 2026/2 calculada da chamada real, não inventada.
UPDATE tb_historico h
   SET frequencia_historico = round(100.0 * c.presentes / c.total, 2)
  FROM (SELECT matricula_id_chamada, count(*) AS total,
               count(*) FILTER (WHERE presente_chamada) AS presentes
          FROM tb_chamada GROUP BY matricula_id_chamada) c
 WHERE c.matricula_id_chamada = h.matricula_id_historico;

-- Prova substitutiva em 2026/1 para quem ficou abaixo de 5,0.
UPDATE tb_historico h
   SET nota_p3_historico = round(4 + ((m.aluno_id_matricula * 29) % 51) / 10.0, 1)
  FROM tb_matricula m
 WHERE m.id_matricula = h.matricula_id_historico
   AND m.status_matricula = 'CONCLUIDO'
   AND h.media_final < 5;


/* ---------------------------------------------------------------------
   9. ATIVIDADES COMPLEMENTARES, BOLSAS, MENSALIDADES E REQUERIMENTOS
   Funcionário 13 é a secretária; 14, o analista; 15, a coordenadora.
   --------------------------------------------------------------------- */
INSERT INTO tb_atividade_complementar (aluno_id_atividade_complementar, descricao_atividade_complementar,
       categoria_atividade_complementar, ch_solicitada_atividade_complementar,
       ch_validada_atividade_complementar, status_validacao_atividade_complementar,
       comprovante_url_atividade_complementar, validado_por_atividade_complementar,
       data_validacao_atividade_complementar)
SELECT a,
       (ARRAY['Curso livre de Python para Data Science','Monitoria de Algoritmos I',
              'Participação na Semana Acadêmica de Computação','Projeto de extensão em escola pública',
              'Hackathon IESB 2026'])[1 + a % 5],
       (ARRAY['Curso livre','Monitoria','Evento científico','Extensão','Competição'])[1 + a % 5],
       10 + (a * 7) % 31,
       CASE (a / 3) % 4 WHEN 0 THEN least(10 + (a * 7) % 31, 20)
                        WHEN 3 THEN 10 + (a * 7) % 31 END,
       (ARRAY['DEFERIDO','PENDENTE','INDEFERIDO','DEFERIDO']::tipo_valid_t[])[1 + (a / 3) % 4],
       format('https://portal.iesb.br/comprovantes/%s.pdf', 900000 + a),
       CASE WHEN (a / 3) % 4 <> 1 THEN 13 + a % 2 END,
       CASE WHEN (a / 3) % 4 <> 1 THEN DATE '2026-08-10' + a % 50 END
  FROM generate_series(3, 116, 3) AS a;

INSERT INTO tb_bolsa_desconto (nome_bolsa_desconto, percentual_bolsa_desconto, ativa_bolsa_desconto) VALUES
  ('Convênio Forças Armadas',  20.00, TRUE),
  ('Bolsa Mérito Acadêmico',   30.00, TRUE),
  ('Convênio Empresarial',     15.00, TRUE),
  ('Bolsa Social (encerrada)', 50.00, FALSE);

INSERT INTO tb_aluno_bolsa (aluno_id_aluno_bolsa, bolsa_id_aluno_bolsa,
                            data_concessao_aluno_bolsa, data_validade_aluno_bolsa)
SELECT a, 1, DATE '2026-02-01', DATE '2026-12-31' FROM generate_series(5, 116, 5) AS a
UNION ALL
SELECT a, 2, DATE '2026-08-01', DATE '2026-12-31' FROM generate_series(11, 116, 11) AS a
UNION ALL
SELECT a, 4, DATE '2025-02-01', DATE '2025-12-31' FROM generate_series(7, 116, 21) AS a;

-- Mensalidades de 2026/2 (agosto a dezembro) dos alunos ativos.
-- Valor final aplica a maior bolsa ATIVA e VIGENTE no mês de competência.
-- Agosto e setembro: pagas, exceto 1 em cada 13 que venceu sem pagamento.
INSERT INTO tb_mensalidade (aluno_id_mensalidade, periodo_letivo_id_mensalidade,
       valor_original_mensalidade, valor_final_mensalidade,
       data_vencimento_mensalidade, data_pagamento_mensalidade, status_mensalidade)
SELECT al.id_aluno, 4, base.valor,
       round(base.valor * (1 - coalesce(desc_max.pct, 0) / 100.0), 2),
       venc,
       CASE WHEN venc < DATE '2026-10-05' AND NOT (al.id_aluno % 13 = 0 AND venc = DATE '2026-09-07')
            THEN venc - (al.id_aluno % 4) END,
       CASE WHEN venc < DATE '2026-10-05' AND al.id_aluno % 13 = 0 AND venc = DATE '2026-09-07' THEN 'VENCIDA'
            WHEN venc < DATE '2026-10-05' THEN 'PAGA'
            ELSE 'ABERTA' END::tipo_mensal_t
  FROM tb_aluno al
 CROSS JOIN generate_series(DATE '2026-08-07', DATE '2026-12-07', INTERVAL '1 month') AS v(venc_ts)
 CROSS JOIN LATERAL (SELECT v.venc_ts::date AS venc) d
 CROSS JOIN LATERAL (
   SELECT CASE cu.curso_id_curriculo WHEN 1 THEN 1348.56 WHEN 2 THEN 489.90 ELSE 399.90 END AS valor
     FROM tb_curriculo cu WHERE cu.id_curriculo = al.curriculo_id_aluno
 ) base
 LEFT JOIN LATERAL (
   SELECT max(b.percentual_bolsa_desconto) AS pct
     FROM tb_aluno_bolsa ab
     JOIN tb_bolsa_desconto b ON b.id_bolsa_desconto = ab.bolsa_id_aluno_bolsa
    WHERE ab.aluno_id_aluno_bolsa = al.id_aluno
      AND b.ativa_bolsa_desconto
      AND d.venc BETWEEN ab.data_concessao_aluno_bolsa AND coalesce(ab.data_validade_aluno_bolsa, d.venc)
 ) desc_max ON TRUE
 WHERE al.status_detalhado_aluno = 'ATIVO';

INSERT INTO tb_requerimento (aluno_id_requerimento, tipo_requerimento, data_abertura_requerimento,
       data_fechamento_requerimento, status_requerimento, parecer_requerimento, responsavel_id_requerimento)
SELECT a,
       (ARRAY['Trancamento de Matrícula','Revisão de Menção','Requerimento Aproveitamento de Estudos',
              'Declarações','Mudança de Turno','Ajuste de Matrícula Fora do Prazo',
              'Requerimento de Exercício Domiciliar','Solicitação de Ementas'])[1 + a % 8],
       TIMESTAMPTZ '2026-08-05 14:00-03' + make_interval(days => a % 55, hours => a % 9),
       CASE WHEN a % 5 IN (0, 1, 2) THEN TIMESTAMPTZ '2026-08-05 14:00-03' + make_interval(days => a % 55 + 3) END,
       (ARRAY['DEFERIDO','DEFERIDO','INDEFERIDO','EM_ANALISE','ABERTO']::tipo_requer_t[])[1 + a % 5],
       CASE a % 5 WHEN 0 THEN 'Deferido conforme regulamento acadêmico.'
                  WHEN 1 THEN 'Deferido. Documentação completa.'
                  WHEN 2 THEN 'Indeferido: fora do prazo do calendário acadêmico.' END,
       CASE WHEN a % 5 <> 4 THEN 13 + a % 3 END
  FROM generate_series(4, 116, 4) AS a;


/* ---------------------------------------------------------------------
   10. CONFERÊNCIA
   Cada linha deve sair com OK. Qualquer FALHA indica carga incompleta.
   --------------------------------------------------------------------- */
SELECT item, quantidade, minimo,
       CASE WHEN quantidade >= minimo THEN 'OK' ELSE 'FALHA' END AS situacao
  FROM (VALUES
    ('alunos',      (SELECT count(*) FROM tb_aluno),     100),
    ('turmas',      (SELECT count(*) FROM tb_turma),       6),
    ('matrículas',  (SELECT count(*) FROM tb_matricula), 300)
  ) AS v(item, quantidade, minimo)
UNION ALL
SELECT 'turmas acima das vagas',
       (SELECT count(*) FROM tb_turma t
         WHERE t.vagas_turma < (SELECT count(*) FROM tb_matricula m
                                 WHERE m.turma_id_matricula = t.id_turma
                                   AND m.status_matricula = 'MATRICULADO')),
       0,
       CASE WHEN (SELECT count(*) FROM tb_turma t
                   WHERE t.vagas_turma < (SELECT count(*) FROM tb_matricula m
                                           WHERE m.turma_id_matricula = t.id_turma
                                             AND m.status_matricula = 'MATRICULADO')) = 0
            THEN 'OK' ELSE 'FALHA' END;
