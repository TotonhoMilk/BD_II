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

   DATA DE CRIAÇÃO:   18/09/2026
   DATA DE ALTERAÇÃO: 23/09/2026 - Antônio

   HISTÓRICO DE REVISÕES: Verificar GitHub
     - https://github.com/TotonhoMilk/BD_II
   ===================================================================== */


/* =====================================================================
                CONFIGURAÇÃO DO AMBIENTE DE BD
   ===================================================================== */

-- =====================================================================
-- PARTE A - Configuração do ambiente de banco de dados em PostgreSQL
--
-- OBJETIVO DO BLOCO: Garantir a usabilidade do script, sem demonstração
-- de erros de execução, enquanto o objeto final do script não tiver sido
-- corrigido e aprovado pelo Prof. Rodrigo Gonçalves.
-- =====================================================================

-- Atenção a essa linha. Não rodar em produção. Essa linha existe qui
-- apenas para realização do script. Favor comentá-la em produção.

-- Remove o esquema "academico" se ele existir, apagando automaticamente 
-- todas as tabelas e objetos vinculados a ele (CASCADE).
DROP SCHEMA IF EXISTS academico CASCADE;

-- Cria o esquema "academico" no banco de dados para organizar e agrupar
-- as tabelas e objetos do Sistema de Matrícula Acadêmica.
CREATE SCHEMA academico;

-- Garante que comandos subsequentes criem/consultem objetos no esquema
-- "academico" por padrão. Caso o banco não possua o esquema "public",
-- retire o termo da linha de comando.
SET search_path TO academico, public;

-- Cria a extensão "btree_gist" para viabilizar o suporte a índices GiST 
-- em tipos tradicionais de dados, essencial para a validação de 
-- restrições avançadas de integridade.
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- =====================================================================



/* =====================================================================
            DEFINIÇÃO DE TIPOS ENUMERADOS E DOMÍNIOS
   ===================================================================== */

-- =====================================================================
-- PARTE A - Tipos Personalizados e Validações de Dados
--
-- OBJETIVO: Definir tipos enumerados (ENUM) para restringir valores 
-- aceitos em campos de status, turnos e classificações, além de criar
-- domínios customizados (DOMAIN) com regras de verificação (CHECK) 
-- para garantir a integridade dos dados numéricos (notas e porcentagens).
-- =====================================================================

-- Tipos enumerados (ENUM) para padronização de domínios discretos
CREATE TYPE turno_t       AS ENUM ('MATUTINO','VESPERTINO','NOTURNO');
CREATE TYPE tipo_disc_t   AS ENUM ('OBRIGATORIA','OPTATIVA');
CREATE TYPE vinculo_t     AS ENUM ('PRE_REQUISITO','CO_REQUISITO');
CREATE TYPE status_mat_t  AS ENUM ('MATRICULADO','TRANCADO','CANCELADO');
CREATE TYPE situacao_t    AS ENUM ('CURSANDO','APROVADO','REPROVADO_NOTA','REPROVADO_FALTA');
CREATE TYPE tipo_sala_t   AS ENUM ('TEORICA','LABORATORIO');

-- Domínios (DOMAIN) com restrição CHECK para integridade de dados numéricos
CREATE DOMAIN nota_t AS numeric(4, 2) CHECK (VALUE BETWEEN 0 AND 10);
CREATE DOMAIN pct_t  AS numeric(5, 2) CHECK (VALUE BETWEEN 0 AND 100);

-- =====================================================================
-- PARTE B - Tipo de intervalo de tempo
--
-- OBJETIVO: Definir o tipo personalizado "timerange" baseado no subtipo 
-- TIME, permitindo trabalhar com intervalos de horários (início e fim) 
-- para validação de chocamento de horários em turmas e alocação de salas.
-- =====================================================================

-- Cria o tipo customizado de intervalo de tempo (timerange) para 
-- manipular faixas de horários (TIME)
CREATE TYPE timerange AS RANGE (subtype = time);

-- =====================================================================



/* =====================================================================
                CRIAÇÃO DAS TABELAS E INTEGRIDADE (DDL)
   ===================================================================== */

-- =====================================================================
-- PARTE A - Estruturação de Tabelas, Chaves e Restrições 
--
-- OBJETIVO DO BLOCO: 
-- Implementar a estrutura relacional do Sistema de Matrícula Acadêmica,
-- definindo a criação de cada tabela juntamente com suas Chaves Primárias 
-- (PK), Chaves Estrangeiras (FK), Restrições de Verificação (CHECK) e 
-- Unicidade (UNIQUE).
--
-- ALERTAS DE EXECUÇÃO:
-- 1. ORDEM DE EXECUÇÃO E DEPENDÊNCIAS:
--    A ordem de criação das tabelas deve respeitar estritamente a hierarquia
--    de dependências do modelo relacional (tabelas "pai" / fortes devem 
--    ser criadas antes das tabelas "filho" / fracas que as referenciam via FK).
--
-- 2. INTEGRIDADE REFERENCIAL E AÇÕES EM CASCATA:
--    Fique atento às regras de integridade referencial definidas nas FKs 
--    (ex: ON DELETE CASCADE, ON DELETE RESTRICT, ON UPDATE CASCADE). 
--    Elas ditarão o comportamento do banco de dados na exclusão ou 
--    alteração de registros correlacionados.
--
-- 3. USO DOS TIPOS PERSONALIZADOS E DOMÍNIOS:
--    Utilize os tipos ENUM (turno_t, tipo_disc_t, etc.) e DOMAIN (nota_t, pct_t)
--    criados na seção anterior para garantir consistência dos atributos.
--
-- 4. RESTRIÇÕES AVANÇADAS E EXCLUSÕES TEMPORAIS:
--    A validação de choques de horário ou alocação de salas pode utilizar 
--    o tipo 'timerange' e restrições 'EXCLUDE USING GIST'
-- =====================================================================


/* ---------------------------------------------------------------------
   TABELA 1: CAMPUS
   --------------------------------------------------------------------- 
      +---------------------+
      | CAMPUS              |
      +---------------------+
      | CAMPUS_ID      (PK) |
      | CAMPUS_NOME         |
      | CAMPUS_CIDADE       |
      +---------------------+
      
      Cria a tabela campus.
          campus_id como chave primária.
          campus_nome, único e não nulo.
          campus_cidade não nulo.
  */

CREATE TABLE campus (
    campus_id      smallint     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    campus_nome    varchar(60)  NOT NULL UNIQUE,
    campus_cidade  varchar(60)  NOT NULL
);

-- ---------------------------------------------------------------------


/* ---------------------------------------------------------------------
   TABELA 2: CURSO
   --------------------------------------------------------------------- 
      +---------------------+
      | CURSO               |
      +---------------------+
      | CURSO_ID       (PK) |
      | CURSO_CODIGO        |
      | CURSO_NOME          |
      | CURSO_GRAU          |
      | CURSO_CH_TOTAL      |
      |                     |
      | CAMPUS_ID      (FK) |
      +---------------------+

      Cria a tabela curso.
          curso_id como chave primária
          curso_codigo, único e não nulo.
          curso_nome não nulo.
          curso_grau não nulo, campo de seleção restrita.
          curso_ch_total, não nulo e maior que zero.
          campus_id chave estrangeira com referencia à tabela campus.
  */

CREATE TABLE curso (
    curso_id         smallint       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    curso_codigo     varchar(10)    NOT NULL UNIQUE,
    curso_nome       varchar(120)   NOT NULL,
    curso_grau       varchar(20)    NOT NULL CHECK (curso_grau IN 
                                      ('BACHARELADO','LICENCIATURA','TECNOLOGO')),
    curso_ch_total   integer        NOT NULL CHECK (curso_ch_total > 0),

    -- Definição de chave estrangeira [curso] --> [campus]
    campus_id        smallint       NOT NULL REFERENCES campus(campus_id) ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------


/* ---------------------------------------------------------------------
   TABELA 3: CURRICULO
   --------------------------------------------------------------------- 
      +------------------------+
      | CURRICULO              |
      +------------------------+
      | CURRICULO_ID      (PK) |
      | CURRICULO_ANO_VIGENCIA |
      | CURRICULO_ ATIVO       |
      |                        |
      | CURSO_ID          (FK) |
      +------------------------+
      
      Cria a tabela curriculo
          curriculo_id como chave primária
          curriculo_ano_vigencia, não nulo, entre 2000 e 2100.
          curriculo_ativo booleano, falso como default.
          curso_id como chave estrangeira com referência a tabela curso.
*/

CREATE TABLE curriculo (
    curriculo_id            integer   GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    curriculo_ano_vigencia  smallint  NOT NULL CHECK (curriculo_ano_vigencia BETWEEN 2000 AND 2100),
    curriculo_ativo         boolean   NOT NULL DEFAULT false,

    -- Definição de chave estrangeira [curriculo] --> [curso]
    curso_id                smallint  NOT NULL REFERENCES curso ON DELETE CASCADE,

    UNIQUE (curso_id, curriculo_ano_vigencia)
);
-- regra: no máximo um currículo ativo por curso (índice único parcial)
CREATE UNIQUE INDEX uq_curriculo_ativo
    ON curriculo (curso_id) WHERE ativo;

-- ---------------------------------------------------------------------


/* ---------------------------------------------------------------------
   TABELA 4: DISCIPLINA
   --------------------------------------------------------------------- 
      +-----------------------+
      | DISCIPLINA            |
      +-----------------------+
      | DISCIPLINA_ID    (PK) |
      | DISCIPLINA_CODIGO     |
      | DISCIPLINA_NOME       |
      | DISCIPLINA_CH_TEORICA |
      | DISCIPLINA_CH_PRATICA |
      | DISCIPLINA_CH_TOTAL   |
      | DISCIPLINA_EMENTA     |
      +-----------------------+
      
      Cria a tabela disciplina
          disciplina_id como chave primária
          disciplina_codigo único e não nulo.
          disciplina_nome não nulo.
          disciplina_ch_teoria único, não nulo, maior que zero.
          disciplina_ch_pratica único, não nulo, maior que zero.
          disciplina_ch_total gerado pela expressão (teoria + pratica)
          disciplina_ementa campo de texto livre.
*/

CREATE TABLE disciplina (
    disciplina_id         integer       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    disciplina_codigo     varchar(10)   NOT NULL UNIQUE,
    disciplina_nome       varchar(120)  NOT NULL,
    disciplina_ch_teoria  smallint      NOT NULL CHECK (disciplina_ch_teoria  >= 0),
    disciplina_ch_pratica smallint      NOT NULL CHECK (disciplina_ch_pratica >= 0),
    disciplina_ch_total   GENERATED ALWAYS AS (disciplina_ch_teoria + disciplina_ch_pratica) STORED,
    disciplina_ementa     text,

    CHECK (disciplina_ch_teoria + disciplina_ch_pratica > 0)
);

-- ---------------------------------------------------------------------


/* ---------------------------------------------------------------------
   TABELA 5: CURRICULO_DISCIPLINA
   --------------------------------------------------------------------- 
      +-------------------------------+
      | CURRICULO_DISCIPLINA          |
      --+-----------------------------+
      | CURRICULO_ID         (PK)(FK) |
      | DISCIPLINA_ID        (PK)(FK) |
      |                               |
      | CURRICULO_DISCIPLINA_PERIODO  |
      | CURRICULO_DISCIPLINA_TIPO     |
      +-------------------------------+
      
      Cria a tabela curriculo_disciplina
          curriculo_id como chave primária e chave estrangeira com referência a curriculo.
          disciplina_id como chave primária e chave estrangeira com referência a disciplina.
          curriculo_disciplina_periodo, não nulo, entre 1 e 12.
          curriculo_disciplina_tipo, não nulo, tipo enum - default OBRIGATORIA.
*/

CREATE TABLE curriculo_disciplina (
    -- Definição de chave estrangeira [curriculo_disciplina] --> [curriculo]
    curriculo_id                 integer      NOT NULL REFERENCES curriculo  ON DELETE CASCADE,

    -- Definição de chave estrangeira [curriculo_disciplina] --> [disciplina]
    disciplina_id                integer      NOT NULL REFERENCES disciplina ON DELETE RESTRICT,

    curriculo_disciplina_periodo smallint     NOT NULL CHECK (curriculo_disciplina_periodo BETWEEN 1 AND 12),
    curriculo_disciplina_tipo    tipo_disc_t  NOT NULL DEFAULT 'OBRIGATORIA',

    PRIMARY KEY (curriculo_id, disciplina_id)
);

-- ---------------------------------------------------------------------


/* ---------------------------------------------------------------------
   TABELA 6: PRE_REQUISITO
   --------------------------------------------------------------------- 
      +-------------------------------+
      | PRE_REQUISITO                 |
      +-------------------------------+
      | DISCIPLINA_ID        (PK)(FK) |
      | REQUISITO_ID         (PK)(FK) |
      |                               |
      | PRE_REQUISITO_VINCULO         |
      +-------------------------------+
      
      Cria a tabela pre_requisito 
          disciplina_id como chave primária e chave estrangeira com referência a disciplina.
          requisito_id como chave primária e chave estrangeira com referência a disciplina.
          pre_requisito_vinculo não nulo, tipo enum - default PRE_REQUISITO.
*/

CREATE TABLE pre_requisito (
    -- Definição de chave estrangeira [pre_requisito] --> [disciplina]
    disciplina_id         integer   NOT NULL REFERENCES disciplina ON DELETE CASCADE,

    -- Definição de chave estrangeira [pre_requisito] --> [disciplina]
    requisito_id          integer   NOT NULL REFERENCES disciplina ON DELETE RESTRICT,

    pre_requisito_vinculo vinculo_t NOT NULL DEFAULT 'PRE_REQUISITO',

    PRIMARY KEY (disciplina_id, requisito_id),
    CHECK (disciplina_id <> requisito_id)
);

-- ---------------------------------------------------------------------


/* ---------------------------------------------------------------------
   TABELA 7: PROFESSOR
   --------------------------------------------------------------------- 
      +-------------------------------+
      | PROFESSOR                     |
      +-------------------------------+
      | PROFESSOR_ID             (PK) |
      |                               |
      | PROFESSOR_MATRICULA           |
      | PROFESSOR_NOME                |
      | PROFESSOR_EMAIL               |
      | PROFESSOR_TITULACAO           |
      +-------------------------------+
      
      Cria a tabela professor
          professor_id como chave primária.
          professor_matricula, não nulo e única.
          professor_nome, não nulo.
          professor_email, não nulo e único [pesquisar REGEX para vallidar email]
          professor_titulacao, não nulo - Enum entre ESPECIALISTA,
                                          MESTRE e DOUTOR.
*/

CREATE TABLE professor (
    professor_id        integer       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    professor_matricula varchar(12)   NOT NULL UNIQUE,
    professor_nome      varchar(120)  NOT NULL,
    professor_email     varchar(120)  NOT NULL UNIQUE,
    professor_titulacao varchar(20)   NOT NULL CHECK (professor_titulacao IN 
                                        ('ESPECIALISTA', 'MESTRE', 'DOUTOR'))
);

-- ---------------------------------------------------------------------


/* ---------------------------------------------------------------------
   TABELA 8: SALA
   --------------------------------------------------------------------- 
      +-------------------------------+
      | SALA                          |
      +-------------------------------+
      | SALA_ID                  (PK) |
      | CAMPUS_ID                (FK) |
      |                               |
      | SALA_CODIGO                   |
      | SALA_CAPACIDADE               |
      | SALA_TIPO                     |
      +-------------------------------+
      
      Cria a tabela professor
          sala_id como chave primária.
          campus_id chave estrangeira com referência a campus.
          sala_codigo, não nulo e único.
          sala_capacidade, não nulo e maior que zero.
          sala_tipo, não nulo e tipo Enum - default TEORICA
*/

CREATE TABLE sala (
    sala_id         integer     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Definição de chave estrangeira [sala] --> [campus]
    campus_id       smallint    NOT NULL REFERENCES campus ON DELETE RESTRICT,
    sala_codigo     varchar(10) NOT NULL,
    sala_capacidade smallint    NOT NULL CHECK (sala_capacidade > 0),
    sala_tipo       tipo_sala_t NOT NULL DEFAULT 'TEORICA',

    UNIQUE (campus_id, sala_codigo)
);
