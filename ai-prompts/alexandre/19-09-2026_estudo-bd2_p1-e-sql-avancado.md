# Registro de uso de IA — estudo de BD2 (19/09 a 24/09/2026)

**Integrante:** Alexandre Vieira
**Ferramenta:** Claude (Anthropic), via Claude Code no VS Code
**Contexto:** preparação para a P1 e prática de SQL avançado, antes do desenvolvimento do Marco 1
**Ambiente:** PostgreSQL 16 local e DBeaver, como indicado pelo professor

---

## Por que este registro faz parte do projeto

Estas sessões não produziram arquivos do repositório, mas foram onde aprendi as técnicas usadas depois nas consultas do Marco 1. O método foi sempre o mesmo: a IA propõe um exercício, eu prevejo o resultado, executo no DBeaver e comparo.

| Estudo | Onde aparece no projeto |
|---|---|
| Junções, `LEFT JOIN` com agregação, `count(*)` contra `count(coluna)` | Q3 (ocupação das turmas) |
| `NOT IN` contra `NOT EXISTS` com NULL | Q5 (alunos sem matrícula ativa) |
| CTE recursiva, nível, caminho e corte de ciclos | Q6 (árvore de pré-requisitos) e Q7 (elegibilidade) |
| View contra materialized view | Q10 (painel candidato a materialized view no Marco 2) |
| `LAG` e variação entre linhas | Q9 (evolução do rendimento) |
| Requisitos e histórias de usuário com critérios de aceite | formato das histórias do documento de requisitos |

---

## Sessão 1 — 19/09: plano de estudo e junções
...

### O que aprendi

- A diferença de cardinalidade entre `INNER JOIN` e `LEFT JOIN` na mesma base (160 contra 170 linhas): as 10 linhas a mais são as que não têm correspondência.
- A configuração do DBeaver: `search_path` só funciona com a conexão ativa no editor.
- `NOT IN` devolvendo 0 linhas quando a subconsulta contém NULL. É a armadilha que a Q5 evita usando `NOT EXISTS`.

---

## Sessão 2 — 20/09: consultas recursivas e views

### Prompts (literais)

1. > sim, vamos de BD2

2. > a rodada dois fica HMDC253, APC1 e a rodada 3 fica APC1, vazio (sem pre requisitos)

3. > no caso, está faltando o pr.requisito_id ?

4. > deveria sair 3, mas no dbeaver saiu só o CCO072

5. > entendi, é porque a coluna nível de quem gerou deu a entender que a primeira linha seria = 0

6. > ah, é porque eu só rodei o ultimo codigo que deixaste = SELECT id, codigo, 100 AS nivel FROM disciplina WHERE codigo = 'CCO072'

7. > algo para não repetir os id?

8. > 1 CCO072 {2} -> 2 / 2 HMDC253 {2,1} -> 2+1 / 3 MDC118 {2,1,6} -> 2+2

9. > cada um devolve uma linha, porem com duas colunas CCO072, 40

10. > 120 linhas, uma por aluno

11. > a view, pois ela executa de novo

12. > imagino que vai ficar 5 pois uma esta sem professor

13. > vamos de escrita

14. > o que é pra fazer exatamente

15. > acho que nao consigo

### O que aprendi

- Como a recursão avança: simulei à mão as "rodadas" (termo âncora, depois cada iteração sobre o resultado da anterior) antes de executar.
- Que rodar só a parte final de um script no DBeaver produz resultado enganoso: o termo âncora sozinho devolve uma linha só.
- O vetor `caminho` (`ARRAY[...] || id`) para não revisitar disciplinas e cortar ciclos. Cheguei a ele pela pergunta "algo para não repetir os id?".
- A view comum reexecuta a consulta a cada leitura; a materialized view guarda o resultado.
- Que um `INNER JOIN` com professor perde a turma sem docente (previ 5 linhas, e não 6).
- Os exercícios de escrita, em que eu redigiria a consulta sem modelo, ficaram difíceis nesta sessão. Registrei isso como ponto a reforçar.

---

## Sessão 3 — 20/09: requisitos e histórias de usuário com um caso pessoal

Pratiquei engenharia de requisitos num MVP pessoal de finanças, que serve de laboratório para as disciplinas do semestre. Os valores e dados financeiros foram omitidos deste registro.

### Prompts (literais, sem os dados pessoais)

1. > todos os professores falam que o importante não é a linguagem, mas o discernimento sobre o conteudo, não é um curso de java, por exemplo, mas sim de POO, não é um curso de postgres, mas sim de BD

2. > como se vc fosse um dev sênior e eu fosse o estagiário de uma empresa de ti

3. > eu estava pensando em começar com a engenharia de software, e mapeamento de requisitos, de forma que "Quanto eu gastei este mês, mesmo?" é um tipo de requisito, pois em uma consulta sql já teria o resultado

4. > onde essa história deve ficar, ou é só um exemplo?

5. > implementar alguma informação que justifique o 0, em vez do 0 "cru"

6. > talvez deixamos um input pré manual, em vez do sistema ingerir o contracheque, ele faz com que o usuario confirme os dados antes do input

7. > como eu escrevo essa historia

8. > ok, vamos continuar com ca3

9. > já fiz os CA3/4

### O que aprendi

- Uma pergunta do usuário ("quanto gastei este mês?") é um requisito, e o critério de aceite é verificável por uma consulta SQL.
- A estrutura "Como / quero / para que", com critérios de aceite numerados e testáveis, que usei depois no documento do Marco 1.
- Que um valor zero sem explicação é um defeito de requisito: o sistema precisa dizer *por que* é zero.

---

## Sessão 4 — 21/09 e 24/09: funções de janela

### Prompts (literais)

1. > como vincular o script ao financas

2. *(resultado colado da consulta com `LAG`: colunas vencimento, total, anterior e variação; valores omitidos)*

3. > para eu adicionar ao dbeaver como nova conexão, e já aproveitar para aplicar BD2

4. *(resultados colados de consultas com variação ano a ano sobre uma base de trabalho; dados omitidos por conterem informação de terceiros)*

### O que aprendi

- `LAG` para comparar cada linha com a anterior e calcular variação. Na primeira linha a anterior é NULL, e não zero, o que evita mostrar uma queda que não existiu. É exatamente a escolha documentada na Q9.
- Aplicar a mesma técnica em bases diferentes da do exercício, para fixar o conceito.

---

## Avaliação

> voltei, fiz a P1 de BD2 — aprendi algumas coisas com as PERGUNTAS

As dúvidas que ficaram da prova orientaram os exercícios feitos depois no DBeaver sobre a base do projeto (registro de 28/09).
