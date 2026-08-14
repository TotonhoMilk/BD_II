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
