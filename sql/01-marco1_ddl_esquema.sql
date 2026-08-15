/* =====================================================================
   PROJETO: Sistema de Matrícula Acadêmica
   DISCIPLINA: Banco de Dados II (CCO072) — IESB 2026/2
   PROFESSOR: Rodrigo Gonçalves
   
   ARQUIVO: 01_marco1_ddl_esquema.sql
   DESCRIÇÃO: Script DDL de criação das tabelas, chaves primárias/estrangeiras,
              constraints e índices do Modelo Lógico (Marco 1).
   
   SGBD: PostgreSQL 17
   BANCO DE DADOS: matricula
   
   AUTORES:
     - Alexandre ... (A preencher)
     - Antônio Alexandre Cavalcante Leite - 2512130086
     - Carlos Eduardo ... (A preencher)
     
   HISTÓRICO DE REVISÕES: Verificar GitHub
     - https://github.com/TotonhoMilk/BD_II
   ===================================================================== */


/* =====================================================================
                TABELA CAMPUS
   ===================================================================== */

CREATE TABLE IF NOT EXISTS campus (
  campus_id SMALLINT PRIMARY KEY,
  campus_nome VARCHAR(60) UNIQUE,
  campus_cidade VARCHAR(60)
);


/* =====================================================================
                TABELA CURSO
   ===================================================================== */

CREATE TABLE IF NOT EXISTS curso (
  curso_id SMALLINT PRIMARY KEY,
  curso_codigo VARCHAR(10) UNIQUE,
  curso_nome VARCHAR(120),
  curso_grau VARCHAR(20),
  curso_ch_total INT,
  campus_id SMALLINT,

  -- Definição de Chave Estrangeira (FK)
  CONSTRAINT fk_curso_campus
    FOREIGN KEY (campus_id)
    REFERENCES campus(campus_id)
);


/* =====================================================================
                TABELA CURRICULO
   ===================================================================== */

CREATE TABLE IF NOT EXISTS curriculo (
  curriculo_id INT PRIMARY KEY,
  curso_id SMALLINT,
  curriculo_ano_vigencia SMALLINT,
  curriculo_ativo BOOLEAN,

  -- Definição de Chave Estrangeira (FK)
  CONSTRAINT fk_curriculo_curso
    FOREIGN KEY (curso_id)
    REFERENCES curso(curso_id)
  );


/* =====================================================================
                TABELA DISCIPLINA
   ===================================================================== */

CREATE TABLE IF NOT EXISTS disciplina (
  disciplina_id INT PRIMARY KEY,
  disciplina_codigo VARCHAR(10) UNIQUE,
  disciplina_nome VARCHAR(120),
  disciplina_ch_teorica SMALLINT,
  disciplina_ch_pratica SMALLINT,
  disciplina_ch_total SMALLINT,
  disciplina_ementa TEXT
);


/* =====================================================================
                TABELA CURRICULO_DISCIPLINA
   ===================================================================== */

CREATE TABLE IF NOT EXISTS curriculo_disciplina (
  curriculo_id INT,
  disciplina_id INT,
  curriculo_disciplina_periodo SMALLINT,
  curriculo_disciplina_tipo VARCHAR(20), -- TIPO_DISC_T

  -- Definição das Chaves Primárias (PK)
  PRIMARY KEY (curriculo_id, disciplina_id),

  -- Definição das Chaves Estrangeiras (FK)
  CONSTRAINT fk_curriculo_disciplina_curriculo
    FOREIGN KEY (curriculo_id)
    REFERENCES curriculo(curriculo_id),

  CONSTRAINT fk_curriculo_disciplina_disciplina
    FOREIGN KEY (disciplina_id)
    REFERENCES disciplina(disciplina_id)
);   


/* =====================================================================
                TABELA PRE_REQUISITO
   ===================================================================== */
   
CREATE TABLE IF NOT EXISTS pre_requisito (
  disciplina_id INT,
  requisito_id INT,
  pre_requisito_vinculo VARCHAR(20), -- VINCULO_T

  -- Definição das Chaves Primárias (PK)
  PRIMARY KEY (disciplina_id, requisito_id),

  -- Definição das Chaves Estrangeiras (FK)
  CONSTRAINT fk_pre_requisito_disciplina
    FOREIGN KEY (disciplina_id)
    REFERENCES disciplina(disciplina_id)

  -- Verificar com o professor sobre a FK do requisito_id
);


/* =====================================================================
                TABELA PROFESSOR  
   ===================================================================== */

CREATE TABLE IF NOT EXISTS professor (
  professor_id INT PRIMARY KEY,
  professor_matricula VARCHAR(20) UNIQUE,
  professor_nome VARCHAR(120),
  professor_email VARCHAR(120) UNIQUE,
  professor_titulacao VARCHAR(20)
);


/* =====================================================================
                TABELA SALA
   ===================================================================== */

CREATE TABLE IF NOT EXISTS sala (
  sala_id INT PRIMARY KEY,
  campus_id SMALLINT,
  sala_codigo VARCHAR(10),
  sala_capacidade SMALLINT,
  sala_tipo VARCHAR(10), -- TIPO_DISC_T
  
  -- Definição da Chave Estrangeira (FK)
  CONSTRAINT fk_sala_campus
    FOREIGN KEY (campus_id)
    REFERENCES campus(campus_id)
);


/* =====================================================================
                TABELA PERIODO_LETIVO
   ===================================================================== */

CREATE TABLE IF NOT EXISTS periodo_letivo (
  periodo_letivo_id SMALLINT PRIMARY KEY,
  periodo_ano SMALLINT,
  periodo_semestre SMALLINT,
  periodo_data_inicio DATE,
  periodo_data_fim DATE
);


/* =====================================================================
                TABELA FERIADO
   ===================================================================== */

CREATE TABLE IF NOT EXISTS feriado (
  feriado_id INT PRIMARY KEY,
  feriado_data DATE,
  feriado_descricao VARCHAR(120),
  campus_id SMALLINT,

  -- Definição de Chave Estrangeira (FK)
  CONSTRAINT fk_feriado_campus
    FOREIGN KEY (campus_id)
    REFERENCES campus(campus_id)
);


/* =====================================================================
                TABELA TURMA
   ===================================================================== */

CREATE TABLE IF NOT EXISTS turma (
  turma_id INT PRIMARY KEY,
  turma_codigo VARCHAR(15),
  disciplina_id INT,
  periodo_letivo_id SMALLINT,
  professor_id INT,
  turma_turno VARCHAR(20), -- TURNO_T
  turma_vagas SMALLINT,

  -- Definição de Chaves Estrangeiras (FK)
  CONSTRAINT fk_turma_disciplina
    FOREIGN KEY (disciplina_id)
    REFERENCES disciplina(disciplina_id),

  CONSTRAINT fk_turma_periodo_letivo
    FOREIGN KEY (periodo_letivo_id)
    REFERENCES periodo_letivo(periodo_letivo_id),

  CONSTRAINT fk_turma_professor
    FOREIGN KEY (professor_id)
    REFERENCES professor(professor_id)
);


/* =====================================================================
                TABELA TURMA_HORARIO
   ===================================================================== */

CREATE TABLE IF NOT EXISTS turma_horario (
  turma_horario_id INT PRIMARY KEY,
  turma_id INT,
  sala_id INT,
  turma_horario_dia_semana SMALLINT,
  turma_horario_faixa VARCHAR(20), -- TIMERANGE

  -- Definição das Chaves Estrangeiras (FK)
  CONSTRAINT fk_turma_horario_turma
    FOREIGN KEY (turma_id)
    REFERENCES turma(turma_id),

  CONSTRAINT fk_turma_horario_sala
    FOREIGN KEY (sala_id)
    REFERENCES sala(sala_id)
);


/* =====================================================================
                TABELA ALUNO  
   ===================================================================== */

CREATE TABLE IF NOT EXISTS aluno (
  aluno_id INT PRIMARY KEY,
  aluno_matricula VARCHAR(20) UNIQUE,
  aluno_nome VARCHAR(120),
  aluno_cpf CHAR(11) UNIQUE,
  aluno_email VARCHAR(120) UNIQUE,
  aluno_nascimento DATE,
  curso_id SMALLINT,
  curriculo_id INT,
  aluno_ingresso DATE,
  aluno_ativo BOOLEAN,

  -- Definição das Chaves Estrangeiras (FK)
  CONSTRAINT fk_aluno_curso
    FOREIGN KEY (curso_id)
    REFERENCES curso(curso_id),

  CONSTRAINT fk_aluno_curriculo
    FOREIGN KEY (curriculo_id)
    REFERENCES curriculo(curriculo_id)
);


/* =====================================================================
                TABELA MATRICULA  
   ===================================================================== */

CREATE TABLE IF NOT EXISTS matricula (
  matricula_id INT PRIMARY KEY,
  aluno_id INT,
  turma_id INT,
  matricula_data_matricula TIMESTAMPTZ,
  matricula_status VARCHAR(20), -- status_mat_t

  -- Definição das Chaves Estrangeiras (FK)
  CONSTRAINT fk_matricula_aluno
    FOREIGN KEY (aluno_id)
    REFERENCES aluno(aluno_id),

  CONSTRAINT fk_matricula_turma
    FOREIGN KEY (turma_id)
    REFERENCES turma(turma_id)
);

/* =====================================================================
                TABELA LOG_MATRICULA  
   ===================================================================== */

CREATE TABLE IF NOT EXISTS log_matricula (
  log_matricula_id BIGINT PRIMARY KEY,
  matricula_id INT,
  log_matricula_acao VARCHAR(20),
  log_matricula_ocorrido_em TIMESTAMPTZ,
  log_matricula_usuario NAME,
  log_matricula_detalhe JSONB,

  -- Definição da Chave Estrangeira (FK)
  CONSTRAINT fk_log_matricula_matricula
    FOREIGN KEY (matricula_id)
    REFERENCES matricula(matricula_id)
);


/* =====================================================================
                TABELA HISTORICO
   ===================================================================== */

CREATE TABLE IF NOT EXISTS historico (
  historico_id INT PRIMARY KEY,
  matricula_id INT,
  historico_nota_a1 FLOAT, -- NOTA_T
  historico_nota_a2 FLOAT, -- NOTA_T
  historico_nota_p3 FLOAT, -- NOTA_T
  historico_frequencia VARCHAR(20), --PCT_T
  historico_situacao VARCHAR(20), -- SITUACAO_T
  historico_media_final NUMERIC(4, 2),

  -- Definição da Chave Estrangeira (FK)
  CONSTRAINT fk_historico_matricula
    FOREIGN KEY (matricula_id)
    REFERENCES matricula(matricula_id)
);
