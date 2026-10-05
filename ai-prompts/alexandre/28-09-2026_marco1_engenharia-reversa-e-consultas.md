# Registro de uso de IA — 28/09/2026

**Integrante:** Alexandre Vieira
**Ferramenta:** Claude (Anthropic), via Claude Code no VS Code
**Marco:** 1
**Tema:** análise do modelo lógico de referência, primeira carga de dados, caderno de consultas e estudo de SQL no DBeaver

---

## Objetivo da sessão

Entender o modelo lógico fornecido pelo professor e o DDL inicial do grupo, apontar divergências entre os dois e produzir uma primeira carga de dados e as consultas obrigatórias do Marco 1.

## Prompts (literais)

1. > o do professor é apenas o modelo lógico "Modelo_Logico_BD2_2026-2.pdf"

2. > no caso, não fui eu que modifiquei, então não escolhi, eu estou tendo que receber o arquivo, analisar e repassar o que vi para meu grupo, pois é um projeto em grupo

3. > vamos fazer engenharia reversa no modelo lógico, e avançar a partir da engenharia de requisitos usando o que o sql que o outro aluno fez como contexto para guia, mas com o modelo lógico e projeto academico como base

4. > A usando junto as histórias de usuario

5. > ah, temos um repo no git https://github.com/TotonhoMilk/BD_II consegue analisar? acho que ninguem adicionou nada ainda além da estrutura

6. > vc consegue fazer um git clone do repo com minha branch e ir subindo updates commit?

7. > sim, mas não faça o commit, vou testar primeiro

8. > vamos adotar uma abordagem clean code, para que qualquer pessoa veja e entenda e funcione perfeitamente o todo, faz sentido?

9. > sim, muito melhor, cada coisa em seu lugar, como uma engenharia real

10. > como é formato txt, pode retirar coisas como negrito ou marcações como traços, deixar clean, mas de fácil leitura, amigável porém profissional

### Estudo no DBeaver (exercícios sobre a própria base)

11. > vamos testar algumas coisas da matéria dentro desse teste no dbeaver?

12. > sobre o Ex. 1: no caso, o (*) conta todas as linhas, e possivelmente vai estar com um numero maior

13. > o A devolve 1, porém o B devolve 0

14. > acredito que a B esteja certa, pois não há nenhuma turma vazia, porém de certo modo, esse vazio também é considerado como uma turma pelo A

15. > vamos fazer assim, eu respondo antes de rodar, ai rodo depois

16. > essa eu não sei ou não entendi bem

17. > Entrega Marco 1 — Data de entrega: 5 de out., 23:59. O SQL deve ser executado em única vez.

## O que a IA produziu

- Parecer comparando o modelo lógico de referência com o DDL inicial do grupo: tipos e domínios ausentes, coluna gerada removida, frequência como texto.
- Documento de requisitos com histórias de usuário e critérios de aceite, derivado do modelo.
- Carga inicial determinística (geração por `generate_series`) respeitando o limite de vagas por turma.
- Caderno de 10 consultas cobrindo as 5 exigências do enunciado: junção externa com agregação, duas recursivas e duas de janela.
- Exercícios guiados no DBeaver: `count(*)` contra `count(coluna)` em LEFT JOIN, e `NOT IN` contra `NOT EXISTS` com NULL.

## Decisões e validação feitas por mim

- Exigi que nada fosse commitado antes de eu testar no meu ambiente.
- Defini a separação entre código executável (`.sql`) e explicação (documentação), para que qualquer integrante entenda o projeto.
- Nos exercícios, respondi a previsão **antes** de executar cada consulta e só depois conferi no DBeaver. Exemplo: previ e confirmei que, numa turma vazia, `count(*)` devolve 1 e `count(m.matricula_id)` devolve 0.
- Interpretei o aviso do professor ("executado em única vez") como: o script roda inteiro, do zero, sem erro e sem intervenção.

## Arquivos resultantes

- `sql/02-carga_de_dados_iniciais.sql` e `sql/03-queries_e_relatorios.sql` (esquema antigo; depois substituídos pela pasta `sql/v2/`)
- `docs/requisitos.md` (primeira versão)
