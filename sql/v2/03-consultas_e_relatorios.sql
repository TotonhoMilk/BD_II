/* =====================================================================
   PROJETO: Sistema de Matrícula Acadêmica
   DISCIPLINA: Banco de Dados II (CCO072) — IESB 2026/2
   PROFESSOR: Rodrigo Gonçalves

   ARQUIVO: 03-consultas_e_relatorios.sql
   DESCRIÇÃO: Caderno de 10 consultas de complexidade crescente sobre o
              esquema "academico" (DDL v2).

   PRÉ-REQUISITO: executar antes o 01 (DDL) e o 02 (carga).

   EXIGÊNCIAS OBRIGATÓRIAS DO ENUNCIADO (seção 4.1)
     Q3  junção externa com agregação
     Q6  recursiva: árvore de pré-requisitos
     Q7  recursiva: disciplinas que o aluno já pode cursar
     Q8  janela: ranking e percentil
     Q9  janela: LAG para evolução do rendimento

   REGRA DE APROVAÇÃO USADA (plano de ensino):
     média final >= 5,0 E frequência >= 75%.

   Os parâmetros de exemplo (aluno, disciplina) ficam numa CTE "p" no
   início de cada consulta, e não em \set: assim o script roda igual no
   psql, no DBeaver e no pgAdmin.
   ===================================================================== */

SET search_path TO academico, public;


/* =====================================================================
   Q1. OFERTA DO PERÍODO 2026/2
   Junção de turma, disciplina, período e docente.
   O professor é LEFT JOIN: a FK da turma é ON DELETE SET NULL, então
   uma turma pode existir temporariamente sem docente — e precisa
   continuar aparecendo na oferta.
   ===================================================================== */
SELECT t.codigo_turma                                          AS turma,
       d.codigo_disciplina                                     AS codigo,
       d.nome_disciplina                                       AS disciplina,
       d.ch_teorica_disciplina + d.ch_pratica_disciplina       AS carga_horaria,
       coalesce(pe.nome_pessoa, '(sem docente)')               AS professor,
       t.turno_turma                                           AS turno,
       t.vagas_turma                                           AS vagas,
       pl.ano_periodo_letivo || '/' || pl.semestre_periodo_letivo AS periodo
  FROM tb_turma t
  JOIN tb_disciplina     d  ON d.id_disciplina      = t.disciplina_id_turma
  JOIN tb_periodo_letivo pl ON pl.id_periodo_letivo = t.periodo_letivo_id_turma
  LEFT JOIN tb_professor   pr ON pr.funcionario_id_professor = t.professor_id_turma
  LEFT JOIN tb_funcionario f  ON f.id_funcionario  = pr.funcionario_id_professor
  LEFT JOIN tb_pessoa      pe ON pe.id_pessoa      = f.pessoa_id_funcionario
 WHERE pl.ano_periodo_letivo = 2026
   AND pl.semestre_periodo_letivo = 2
 ORDER BY t.codigo_turma, d.codigo_disciplina;


/* =====================================================================
   Q2. GRADE DE HORÁRIOS DE UM ALUNO
   Cada turma tem dois encontros na mesma noite. string_agg junta os
   encontros num campo só, para a turma não aparecer duas vezes.
   ===================================================================== */
WITH p AS (SELECT '2521300003'::varchar AS ra)
SELECT a.matricula_aluno                  AS ra,
       pe.nome_pessoa                     AS aluno,
       t.codigo_turma                     AS turma,
       d.nome_disciplina                  AS disciplina,
       m.status_matricula                 AS situacao,
       string_agg(
         (ARRAY['dom','seg','ter','qua','qui','sex','sáb'])[h.dia_semana_turma_horario]
         || ' ' || to_char(lower(h.faixa_turma_horario), 'HH24:MI')
         || '-' || to_char(upper(h.faixa_turma_horario), 'HH24:MI')
         || ' (' || s.codigo_sala || ')',
         ' | ' ORDER BY lower(h.faixa_turma_horario)
       )                                  AS encontros
  FROM p
  JOIN tb_aluno        a  ON a.matricula_aluno = p.ra
  JOIN tb_pessoa       pe ON pe.id_pessoa      = a.pessoa_id_aluno
  JOIN tb_matricula    m  ON m.aluno_id_matricula = a.id_aluno
  JOIN tb_turma        t  ON t.id_turma        = m.turma_id_matricula
  JOIN tb_disciplina   d  ON d.id_disciplina   = t.disciplina_id_turma
  JOIN tb_periodo_letivo pl ON pl.id_periodo_letivo = t.periodo_letivo_id_turma
  LEFT JOIN tb_turma_horario h ON h.turma_id_turma_horario = t.id_turma
  LEFT JOIN tb_sala    s  ON s.id_sala         = h.sala_id_turma_horario
 WHERE pl.ano_periodo_letivo = 2026 AND pl.semestre_periodo_letivo = 2
 GROUP BY a.matricula_aluno, pe.nome_pessoa, t.codigo_turma, d.nome_disciplina, m.status_matricula
 ORDER BY t.codigo_turma, d.nome_disciplina;


/* =====================================================================
   Q3. OCUPAÇÃO DAS TURMAS               [JUNÇÃO EXTERNA COM AGREGAÇÃO]
   O LEFT JOIN mantém visível a turma sem nenhuma matrícula.
   count(m.id_matricula), e não count(*): com LEFT JOIN, count(*) conta
   a linha de NULLs e devolveria 1 onde o correto é 0.
   FILTER conta só as matrículas ativas: trancamento e cancelamento
   liberam a vaga (História 1, CA3).
   ===================================================================== */
SELECT t.codigo_turma                     AS turma,
       d.nome_disciplina                  AS disciplina,
       pl.ano_periodo_letivo || '/' || pl.semestre_periodo_letivo AS periodo,
       t.vagas_turma                      AS vagas,
       count(m.id_matricula)              AS registros,
       count(m.id_matricula) FILTER (WHERE m.status_matricula = 'MATRICULADO') AS ativos,
       count(m.id_matricula) FILTER (WHERE m.status_matricula = 'TRANCADO')    AS trancados,
       count(m.id_matricula) FILTER (WHERE m.status_matricula = 'CANCELADO')   AS cancelados,
       t.vagas_turma
         - count(m.id_matricula) FILTER (WHERE m.status_matricula = 'MATRICULADO') AS vagas_livres,
       round(100.0 * count(m.id_matricula) FILTER (WHERE m.status_matricula = 'MATRICULADO')
             / t.vagas_turma, 1)          AS ocupacao_pct
  FROM tb_turma t
  JOIN tb_disciplina     d  ON d.id_disciplina      = t.disciplina_id_turma
  JOIN tb_periodo_letivo pl ON pl.id_periodo_letivo = t.periodo_letivo_id_turma
  LEFT JOIN tb_matricula m  ON m.turma_id_matricula = t.id_turma
 WHERE pl.ano_periodo_letivo = 2026 AND pl.semestre_periodo_letivo = 2
 GROUP BY t.id_turma, t.codigo_turma, d.nome_disciplina, pl.ano_periodo_letivo,
          pl.semestre_periodo_letivo, t.vagas_turma
 ORDER BY ocupacao_pct DESC;


/* =====================================================================
   Q4. APROVEITAMENTO POR DISCIPLINA (turmas concluídas)
   Separa reprovação por nota de reprovação por falta: causas
   distintas, que pedem intervenção distinta. Frequência abaixo de 75%
   reprova mesmo com média suficiente (História 3, CA3).
   ===================================================================== */
SELECT d.codigo_disciplina                AS codigo,
       d.nome_disciplina                  AS disciplina,
       count(*)                           AS avaliados,
       count(*) FILTER (WHERE h.media_final >= 5 AND h.frequencia_historico >= 75) AS aprovados,
       count(*) FILTER (WHERE h.frequencia_historico < 75)                         AS reprov_falta,
       count(*) FILTER (WHERE h.media_final < 5 AND h.frequencia_historico >= 75)  AS reprov_nota,
       count(*) FILTER (WHERE h.nota_p3_historico IS NOT NULL)                     AS fizeram_p3,
       round(100.0 * count(*) FILTER (WHERE h.media_final >= 5 AND h.frequencia_historico >= 75)
             / count(*), 1)               AS aprovacao_pct,
       round(avg(h.media_final), 2)       AS media_geral,
       round(avg(h.frequencia_historico), 1) AS freq_media
  FROM tb_historico h
  JOIN tb_matricula  m ON m.id_matricula  = h.matricula_id_historico
  JOIN tb_turma      t ON t.id_turma      = m.turma_id_matricula
  JOIN tb_disciplina d ON d.id_disciplina = t.disciplina_id_turma
 WHERE m.status_matricula = 'CONCLUIDO'
 GROUP BY d.id_disciplina, d.codigo_disciplina, d.nome_disciplina
HAVING count(*) >= 5
 ORDER BY aprovacao_pct;


/* =====================================================================
   Q5. ALUNOS SEM MATRÍCULA ATIVA EM 2026/2
   NOT EXISTS, e não NOT IN: se a subconsulta devolvesse algum NULL,
   o NOT IN produziria conjunto vazio silenciosamente.
   ===================================================================== */
SELECT a.matricula_aluno                  AS ra,
       pe.nome_pessoa                     AS aluno,
       c.nome_curso                       AS curso,
       a.status_detalhado_aluno           AS vinculo,
       a.ingresso_aluno                   AS ingresso
  FROM tb_aluno a
  JOIN tb_pessoa    pe ON pe.id_pessoa   = a.pessoa_id_aluno
  JOIN tb_curriculo cu ON cu.id_curriculo = a.curriculo_id_aluno
  JOIN tb_curso     c  ON c.id_curso     = cu.curso_id_curriculo
 WHERE NOT EXISTS (
         SELECT 1
           FROM tb_matricula m
           JOIN tb_turma t ON t.id_turma = m.turma_id_matricula
           JOIN tb_periodo_letivo pl ON pl.id_periodo_letivo = t.periodo_letivo_id_turma
          WHERE m.aluno_id_matricula = a.id_aluno
            AND m.status_matricula = 'MATRICULADO'
            AND pl.ano_periodo_letivo = 2026 AND pl.semestre_periodo_letivo = 2)
 ORDER BY a.status_detalhado_aluno, pe.nome_pessoa;


/* =====================================================================
   Q6. ÁRVORE DE PRÉ-REQUISITOS                             [RECURSIVA]
   Desce o grafo a partir de uma disciplina. A coluna "caminho"
   acumula os ids visitados e corta ciclos: o CHECK do DDL impede só o
   auto-laço (A exige A), não o ciclo A > B > A — um erro de cadastro
   bastaria para a recursão não terminar.
   Co-requisito fica fora: é cursado junto, não antes.
   ===================================================================== */
WITH RECURSIVE
p AS (SELECT 'MDC140'::varchar AS codigo),
arvore AS (
    SELECT d.id_disciplina, d.codigo_disciplina, d.nome_disciplina,
           0                              AS nivel,
           ARRAY[d.id_disciplina]         AS caminho,
           d.codigo_disciplina::text      AS trilha
      FROM tb_disciplina d
      JOIN p ON p.codigo = d.codigo_disciplina

    UNION ALL

    SELECT r.id_disciplina, r.codigo_disciplina, r.nome_disciplina,
           a.nivel + 1,
           a.caminho || r.id_disciplina,
           a.trilha || ' <- ' || r.codigo_disciplina
      FROM arvore a
      JOIN tb_pre_requisito pr ON pr.disciplina_id_pre_requisito = a.id_disciplina
                              AND pr.vinculo_pre_requisito = 'PRE_REQUISITO'
      JOIN tb_disciplina    r  ON r.id_disciplina = pr.requisito_id_pre_requisito
     WHERE NOT (r.id_disciplina = ANY (a.caminho))
)
SELECT nivel,
       repeat('    ', nivel) || codigo_disciplina AS hierarquia,
       nome_disciplina                            AS disciplina,
       trilha                                     AS caminho_ate_a_raiz
  FROM arvore
 ORDER BY nivel, codigo_disciplina;


/* =====================================================================
   Q7. DISCIPLINAS QUE O ALUNO JÁ PODE CURSAR               [RECURSIVA]
   História 2. "fecho" é o fecho transitivo do grafo: para cada
   disciplina, todos os ancestrais em qualquer profundidade. Elegível é
   a disciplina do currículo DO ALUNO sem nenhum ancestral pendente.
   Concluída = matrícula concluída com média >= 5 e frequência >= 75%,
   ou aproveitamento de estudos deferido (História 6, CA4).
   ===================================================================== */
WITH RECURSIVE
p AS (SELECT '2521300003'::varchar AS ra),
aluno AS (
    SELECT a.id_aluno, a.curriculo_id_aluno FROM tb_aluno a JOIN p ON p.ra = a.matricula_aluno
),
concluidas AS (
    SELECT t.disciplina_id_turma AS id_disciplina
      FROM aluno al
      JOIN tb_matricula m ON m.aluno_id_matricula = al.id_aluno AND m.status_matricula = 'CONCLUIDO'
      JOIN tb_turma     t ON t.id_turma = m.turma_id_matricula
      JOIN tb_historico h ON h.matricula_id_historico = m.id_matricula
     WHERE h.media_final >= 5 AND h.frequencia_historico >= 75
    UNION
    SELECT ap.disciplina_id_aproveitamento_disciplina
      FROM aluno al
      JOIN tb_aproveitamento_disciplina ap ON ap.aluno_id_aproveitamento_disciplina = al.id_aluno
     WHERE ap.status_aprovacao_aproveitamento_disciplina = 'DEFERIDO'
),
fecho AS (
    SELECT pr.disciplina_id_pre_requisito AS id_disciplina,
           pr.requisito_id_pre_requisito  AS id_requisito,
           ARRAY[pr.disciplina_id_pre_requisito, pr.requisito_id_pre_requisito] AS caminho
      FROM tb_pre_requisito pr
     WHERE pr.vinculo_pre_requisito = 'PRE_REQUISITO'
    UNION ALL
    SELECT f.id_disciplina, pr.requisito_id_pre_requisito, f.caminho || pr.requisito_id_pre_requisito
      FROM fecho f
      JOIN tb_pre_requisito pr ON pr.disciplina_id_pre_requisito = f.id_requisito
                              AND pr.vinculo_pre_requisito = 'PRE_REQUISITO'
     WHERE NOT (pr.requisito_id_pre_requisito = ANY (f.caminho))
)
SELECT d.codigo_disciplina                 AS codigo,
       d.nome_disciplina                   AS disciplina,
       cd.periodo_curriculo_disciplina     AS periodo_sugerido,
       cd.tipo_curriculo_disciplina        AS tipo,
       (SELECT count(DISTINCT f.id_requisito) FROM fecho f
         WHERE f.id_disciplina = d.id_disciplina) AS pre_requisitos_na_arvore
  FROM aluno al
  JOIN tb_curriculo_disciplina cd ON cd.curriculo_id_curriculo_disciplina = al.curriculo_id_aluno
  JOIN tb_disciplina d ON d.id_disciplina = cd.disciplina_id_curriculo_disciplina
 WHERE NOT EXISTS (SELECT 1 FROM concluidas c WHERE c.id_disciplina = d.id_disciplina)
   AND NOT EXISTS (SELECT 1 FROM fecho f
                    WHERE f.id_disciplina = d.id_disciplina
                      AND NOT EXISTS (SELECT 1 FROM concluidas c WHERE c.id_disciplina = f.id_requisito))
 ORDER BY cd.periodo_curriculo_disciplina, d.codigo_disciplina;


/* =====================================================================
   Q8. RANKING E PERCENTIL POR TURMA              [JANELA: RANK E PERCENTIL]
   OVER preserva as linhas; GROUP BY as colapsaria.
   ROW_NUMBER numera sem empate, RANK empata e pula, DENSE_RANK empata
   e não pula. NTILE divide por quantidade de linhas, não por valor.
   A cláusula WINDOW declara a janela uma vez para as cinco funções.
   ===================================================================== */
SELECT t.codigo_turma || ' ' || d.codigo_disciplina AS turma,
       pe.nome_pessoa                               AS aluno,
       h.media_final                                AS media,
       h.frequencia_historico                       AS frequencia,
       ROW_NUMBER()  OVER w                         AS linha,
       RANK()        OVER w                         AS posicao,
       DENSE_RANK()  OVER w                         AS posicao_densa,
       round((PERCENT_RANK() OVER w)::numeric, 3)   AS percentil,
       NTILE(4)      OVER w                         AS quartil,
       round(avg(h.media_final) OVER (PARTITION BY t.id_turma), 2) AS media_turma,
       round(h.media_final - avg(h.media_final) OVER (PARTITION BY t.id_turma), 2) AS desvio
  FROM tb_historico h
  JOIN tb_matricula  m  ON m.id_matricula  = h.matricula_id_historico
  JOIN tb_turma      t  ON t.id_turma      = m.turma_id_matricula
  JOIN tb_disciplina d  ON d.id_disciplina = t.disciplina_id_turma
  JOIN tb_aluno      a  ON a.id_aluno      = m.aluno_id_matricula
  JOIN tb_pessoa     pe ON pe.id_pessoa    = a.pessoa_id_aluno
 WHERE m.status_matricula = 'CONCLUIDO'
WINDOW w AS (PARTITION BY t.id_turma ORDER BY h.media_final DESC)
 ORDER BY turma, posicao;


/* =====================================================================
   Q9. EVOLUÇÃO DO RENDIMENTO DO ALUNO                     [JANELA: LAG]
   Para cada aluno, a sequência das suas notas em ordem cronológica:
   médias finais de 2026/1 e notas da A1 de 2026/2 (a A2 ainda não
   aconteceu). LAG compara cada uma com a anterior. Sem anterior, LAG
   devolve NULL — o correto: usar 0 produziria uma queda inexistente.
   Dois frames lado a lado: média móvel de 3 e média acumulada.
   ===================================================================== */
WITH notas AS (
    SELECT a.id_aluno, pe.nome_pessoa, d.codigo_disciplina,
           pl.ano_periodo_letivo || '/' || pl.semestre_periodo_letivo AS periodo,
           coalesce(h.media_final, h.nota_a1_historico)                AS nota,
           CASE WHEN h.media_final IS NULL THEN 'A1' ELSE 'média' END  AS referencia,
           coalesce(av.data_avaliacao, pl.data_fim_periodo_letivo)     AS data_ref
      FROM tb_historico h
      JOIN tb_matricula      m  ON m.id_matricula  = h.matricula_id_historico
      JOIN tb_turma          t  ON t.id_turma      = m.turma_id_matricula
      JOIN tb_disciplina     d  ON d.id_disciplina = t.disciplina_id_turma
      JOIN tb_periodo_letivo pl ON pl.id_periodo_letivo = t.periodo_letivo_id_turma
      JOIN tb_aluno          a  ON a.id_aluno      = m.aluno_id_matricula
      JOIN tb_pessoa         pe ON pe.id_pessoa    = a.pessoa_id_aluno
      LEFT JOIN tb_avaliacao av ON av.turma_id_avaliacao = t.id_turma
                               AND av.titulo_avaliacao = 'A1'
                               AND h.media_final IS NULL
     WHERE m.status_matricula IN ('CONCLUIDO', 'MATRICULADO')
       AND a.id_aluno IN (7, 21, 42)
)
SELECT nome_pessoa AS aluno, periodo, codigo_disciplina AS disciplina, referencia, nota,
       LAG(nota) OVER w                                AS nota_anterior,
       round(nota - LAG(nota) OVER w, 2)               AS variacao,
       CASE WHEN LAG(nota) OVER w IS NULL THEN 'primeira'
            WHEN nota > LAG(nota) OVER w  THEN 'subiu'
            WHEN nota < LAG(nota) OVER w  THEN 'caiu'
            ELSE 'manteve' END                         AS tendencia,
       round(avg(nota) OVER (PARTITION BY id_aluno ORDER BY data_ref, codigo_disciplina
                             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS media_movel_3,
       round(avg(nota) OVER (PARTITION BY id_aluno ORDER BY data_ref, codigo_disciplina
                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS media_acumulada
  FROM notas
WINDOW w AS (PARTITION BY id_aluno ORDER BY data_ref, codigo_disciplina)
 ORDER BY aluno, data_ref, disciplina;


/* =====================================================================
   Q10. PAINEL DE INDICADORES POR CURSO
   Combina CTEs encadeadas, agregação, junção externa e janela.
   Acadêmico (média e aprovação em 2026/1) e financeiro (inadimplência
   em 2026/2) no mesmo painel. Candidata a MATERIALIZED VIEW no Marco 2.
   sum(...) OVER () sem PARTITION nem ORDER cobre todo o resultado:
   é o total geral na mesma passagem, sem subconsulta.
   ===================================================================== */
WITH academico AS (
    SELECT cu.curso_id_curriculo AS id_curso,
           round(avg(h.media_final), 2) AS media,
           round(100.0 * count(*) FILTER (WHERE h.media_final >= 5 AND h.frequencia_historico >= 75)
                 / nullif(count(*), 0), 1) AS aprovacao_pct
      FROM tb_historico h
      JOIN tb_matricula m  ON m.id_matricula = h.matricula_id_historico AND m.status_matricula = 'CONCLUIDO'
      JOIN tb_aluno     a  ON a.id_aluno = m.aluno_id_matricula
      JOIN tb_curriculo cu ON cu.id_curriculo = a.curriculo_id_aluno
     GROUP BY cu.curso_id_curriculo
),
financeiro AS (
    SELECT cu.curso_id_curriculo AS id_curso,
           sum(ms.valor_final_mensalidade) FILTER (WHERE ms.status_mensalidade = 'PAGA')    AS recebido,
           sum(ms.valor_final_mensalidade) FILTER (WHERE ms.status_mensalidade = 'VENCIDA') AS em_atraso,
           count(DISTINCT ms.aluno_id_mensalidade) FILTER (WHERE ms.status_mensalidade = 'VENCIDA') AS inadimplentes
      FROM tb_mensalidade ms
      JOIN tb_aluno     a  ON a.id_aluno = ms.aluno_id_mensalidade
      JOIN tb_curriculo cu ON cu.id_curriculo = a.curriculo_id_aluno
     GROUP BY cu.curso_id_curriculo
),
por_curso AS (
    SELECT c.id_curso, c.codigo_curso, c.nome_curso, ca.nome_campus,
           count(a.id_aluno)                                                     AS alunos,
           count(a.id_aluno) FILTER (WHERE a.status_detalhado_aluno = 'ATIVO')   AS ativos
      FROM tb_curso c
      JOIN tb_campus ca ON ca.id_campus = c.campus_id_curso
      LEFT JOIN tb_curriculo cu ON cu.curso_id_curriculo = c.id_curso
      LEFT JOIN tb_aluno     a  ON a.curriculo_id_aluno  = cu.id_curriculo
     GROUP BY c.id_curso, c.codigo_curso, c.nome_curso, ca.nome_campus
)
SELECT pc.codigo_curso                    AS codigo,
       pc.nome_curso                      AS curso,
       pc.nome_campus                     AS campus,
       pc.alunos, pc.ativos,
       round(100.0 * pc.alunos / nullif(sum(pc.alunos) OVER (), 0), 1) AS pct_dos_alunos,
       ac.media                           AS media_2026_1,
       ac.aprovacao_pct,
       RANK() OVER (ORDER BY ac.media DESC NULLS LAST) AS posicao_media,
       coalesce(fi.recebido, 0)           AS recebido_2026_2,
       coalesce(fi.em_atraso, 0)          AS em_atraso,
       coalesce(fi.inadimplentes, 0)      AS inadimplentes
  FROM por_curso pc
  LEFT JOIN academico  ac ON ac.id_curso = pc.id_curso
  LEFT JOIN financeiro fi ON fi.id_curso = pc.id_curso
 ORDER BY posicao_media;
