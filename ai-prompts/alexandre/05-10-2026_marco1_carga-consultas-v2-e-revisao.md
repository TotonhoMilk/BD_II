# Registro de uso de IA — 05/10/2026

**Integrante:** Alexandre Vieira
**Ferramenta:** Claude (Anthropic), via Claude Code no VS Code
**Marco:** 1
**Tema:** carga e consultas sobre o DDL v2 do grupo, revisão do DDL, revisão do documento de requisitos e preparação da entrega

---

## Objetivo da sessão

Povoar o esquema DDL v2 (feito pelo Antônio), adaptar as 10 consultas ao novo esquema, revisar o DDL e o documento de requisitos contra o que foi implementado, e preparar a entrega do Marco 1.

## Prompts (literais)

1. > o que o antonio fez, mas ainda falta povoar, de acordo com ele.
   *(anexo: `marco_1_teste.sql`, DDL v2 com auditoria)*

2. > faça um texto para que eu envie ao antônio para correções

3. > veja se o problema não é minha parte, que é esse pdf que eu fiz
   *(anexo: PDF do documento de requisitos)*

4. > obs: hoje é entrega de marco 1

5. > o antonio falou: "Eu entendi... Pode aplicar..."

6. > preciso mudar o pdf, vou mudar agora

7. > faça o docx

8. > e se eu fizer em formato latex com overleaf

9. > o antonio decidiu que vai fazer os ajustes

10. > ele finaliza a parte dele, e eu a minha, vamos atualizar o git com minha parte, e já preparar o commit da minha parte

11. > o ponto: "Registro de Prompts de Inteligência Artificial [...] Todos os membros do grupo mantêm o registro de suas interações com as IAs nas pastas dedicadas dentro de ai-prompts/"

## O que a IA produziu

- **Carga do esquema v2** (`sql/v2/02-carga_de_dados_iniciais.sql`): 120 alunos, 16 turmas e 508 matrículas, com as 33 tabelas povoadas e nenhuma turma acima das vagas. É determinística e pode ser reexecutada sem duplicar dados.
- **As 10 consultas reescritas** (`sql/v2/03-consultas_e_relatorios.sql`) para os nomes do esquema v2, com os parâmetros numa CTE em vez de `\set`, para rodar no psql, no DBeaver e no pgAdmin.
- **Revisão do DDL v2**, com cinco apontamentos e a correção sugerida de cada um: antichoque de sala ignorando o período letivo, falta do antichoque de professor, `UNIQUE` em pessoa-aluno contradizendo a História 0, função `SECURITY DEFINER` sem `search_path` fixo e log alterável, e unicidade de período que não pegava o bimestre nulo.
- **Mensagem para o Antônio** descrevendo os cinco pontos.
- **Revisão do documento de requisitos contra o DDL.** Encontrou o RP1 contraditório com a História 0 (origem da restrição pessoa-aluno), o RO5 e o RO6 ambíguos quanto ao período letivo, a convenção de nomes do documento invertida em relação ao DDL e uma matriz de rastreabilidade que prometia no Marco 1 itens não implementados.
- **Versão `.docx` do documento** com essas correções.

## Testes executados

Todos em PostgreSQL local, num banco vazio, com os três scripts concatenados:

- `01 + 02 + 03` executam de uma vez, sem erro (código de saída 0).
- A carga, executada duas vezes seguidas, mantém os mesmos números.
- Tentativas de violação das regras, para conferir as correções propostas ao DDL: sala ocupada no mesmo período (recusada), mesma sala em outro período (aceita), professor em dois horários (recusado), mesma pessoa em dois cursos (aceita), `UPDATE` e `DELETE` no log de auditoria (recusados) e período letivo duplicado (recusado).

## Decisões e validação feitas por mim

- Levei os apontamentos ao responsável pelo DDL (Antônio) antes de qualquer mudança no arquivo dele. A decisão final sobre o DDL ficou com ele.
- Reconheci que dois dos problemas do DDL tinham origem no meu documento (RP1 e RO5/RO6) e corrigi o documento.
- Mantive na matriz de rastreabilidade só o que o Marco 1 realmente entrega, movendo o restante para o Marco 2.
- Separei no Git o que é da minha responsabilidade (requisitos, modelagem, carga e consultas) do DDL, que segue com o Antônio, em três commits distintos.

## Arquivos resultantes

- `docs/Requisitos_BD2_Marco1.docx`
- `sql/v2/02-carga_de_dados_iniciais.sql`
- `sql/v2/03-consultas_e_relatorios.sql`
