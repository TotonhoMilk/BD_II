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
