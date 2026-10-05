# Registro de uso de IA — 29/09/2026

**Integrante:** Alexandre Vieira
**Ferramenta:** Claude (Anthropic), via Claude Code no VS Code
**Marco:** 1
**Tema:** engenharia de requisitos a partir do portal do IESB, modelo conceitual (DER) e modelo lógico no draw.io

---

## Objetivo da sessão

Refazer o processo completo pedido pelo professor (requisitos, conceitual, lógico e SQL), tendo o portal acadêmico do IESB como referência de realidade e o modelo lógico do professor como guia de escopo.

## Prompts (literais)

### Escopo e convenções

1. > ainda precisamos alinhar os requisitos, como o requisito de boas praticas que o professor exigiu, de nomear as tabelas com "tb_nome" e "id_tabela" ou "tabela_id"

2. > id_tabela ou tabela_id, ele sugeriu id_tabela mas ao perguntarem sobre o formato tabela_id ele falou que não há problema, sobre o tb_ foi na ultima aula agora
   *(anexo: fotos do quadro da aula, com o rascunho TB_CAMPUS, TB_PAIS, TB_ESTADO, TB_PREDIO, TB_BLOCO, TB_SALA)*

3. > o modelo lógico contem erros, o proprio docente citou e colocou propositalmente

4. > escopo ser banco de dados como do IESB. "O SQL deve ser executado em única vez."

5. > o projeto é de "banco de dados" não de uma tabela ou algo em especifico, a criação do banco de dados, com o foco em ser algo academico com base no IESB (podendo possivelmente até substituir o do IESB)

6. > o projeto não tem minimo ou máximo, então vamos usar tudo que puder, claro, com gerência e sentido lógico, vamos listar agora os requisitos com base nas imagens

7. > refazemos tudo agora, foco marco 1!

### Levantamento a partir do portal

8. > vamos continuar com a questão de requisitos e historias de usuario
   *(anexos: telas do portal do aluno — menu, histórico, horários de aulas, disciplinas matriculadas, serviços acadêmicos)*

9. > vamos usar POO para tratar de pessoa, tenhamos pessoa, atua como um tipo de classe, onde aluno ou professor ou funcionario, são como objetos da mesma classe, de forma que todo aluno é uma pessoa, mas nem toda pessoa é um aluno, porém um aluno que é uma pessoa também pode ser funcionario, talvez até mesmo professor, o que vai diferenciar vai ser a matricula, por exemplo, eu faço 3 graduações [...] tenho 3 matriculas, cada uma com seus históricos, disciplinas e vinculos, porém tem uma informação interessante, que são as disciplinas optativas

10. > no histórico contem uma disciplina optativa como parte da grade do curso de ciencia da computação, porem como neste arquivo, 6 disciplinas constam como optativas, porem não encontrei algo falando sobre limites
    *(anexo: matriz curricular de Ciência da Computação 2020/1)*

11. > a questão é, isso muda muito, depende do curso, da modalidade, e etc. por exemplo engenharia de software e matematica ead, possui ciclos de trimestres
    *(anexos: matrizes de Engenharia de Software e Matemática EAD)*

12. > sim, certo, vamos primeiro colocar por escrito em requisitos

13. > vamos usar o proximo dado para atualizar o escopo e melhorar as coisas (se for o caso): Etapa 1: Análise de Requisitos (Visão de Produto) — Módulo 1: Gestão de Estrutura e Grade; Módulo 2: Vida Acadêmica e Alocação; Módulo 3: Faturamento e Benefícios; Módulo 4: Compliance e Segurança [...]

14. > vamos finalizar os requisitos

### Modelo conceitual e lógico no draw.io

15. > no caso, o pedido do professor é que seja usado o draw.io, consegue usar ele?

16. > vamos agora fazer um plano de construção desse arquivo, para que ele esteja visualmente coerente e não tenha problemas de entendimento, podendo usar abordagens como cores, ordem de lógica de uso e variações que são de agregação ao uso

17. > do zero, vamos fazer uma pagina, porém deixar o modelo de duas paginas como possibilidade futura

18. > perceba que as linhas de relacionamento são um problema visual, faça um plano para melhorar isso

19. > faça o plano de construção do modelo lógico usando tabela internal storage, com o "mapa" todo ligado

20. > C, o professor especificou Internal Storage porém com organização tipo A, então ficou praticamente C

21. > faça o logico todo conectado, não apenas modulos separados

22. > as linhas estão em cima das tabelas, e passando sobre elas, ou se misturando com outras linhas, ficando dificil de ver o mapa inteiro

23. > A. podemos fazer uma gerencia sobre as linhas, como organização delas, tamanhos, larguras, cores e etc

## O que a IA produziu

- `docs/levantamento-portal.md`: o que as telas do portal mostram, separado do que é inferência.
- `docs/requisitos.md`: 46 requisitos em 10 subsistemas e 14 histórias de usuário com critérios de aceite.
- Geradores Python dos diagramas e os arquivos `.drawio`: DER conceitual com 35 entidades em 7 blocos, e modelo lógico no formato Internal Storage com as chaves estrangeiras ligadas coluna a coluna, em corredores e cores por bloco.

## Decisões e validação feitas por mim

- **Pessoa e papéis.** Pessoa é a entidade base; aluno, professor e funcionário são papéis. O RA pertence ao vínculo, não à pessoa, para que uma pessoa com três graduações tenha um único CPF e três históricos. É a decisão D3 do documento.
- **Ciclos e módulos por currículo.** Pelas matrizes reais, Ciência da Computação (presencial) tem 4 ciclos de 2 módulos, e Engenharia de Software e Matemática (EAD) têm 4 ciclos de 4 módulos, trimestrais. Por isso a organização é propriedade do currículo, e não um número fixo. É a decisão D1.
- **Escopo.** O banco acadêmico completo, tendo o portal do IESB como referência, incluindo o módulo financeiro. É a decisão D2.
- **Formato do diagrama.** Internal Storage, como pedido pelo professor, mas organizado como tabela, com uma linha por atributo, para que cada chave estrangeira saia da coluna exata.
- **Legibilidade do mapa.** Pedi que todas as tabelas ficassem conectadas num só mapa e que as linhas tivessem gerenciamento próprio (corredores, cores e espessuras), depois de conferir no draw.io que estavam sobrepostas.

## Arquivos resultantes

- `docs/levantamento-portal.md`
- `docs/requisitos.md`
- `modelagem/der-conceitual.drawio`, `modelagem/modelo-logico.drawio`
- `modelagem/gerar_der.py`, `modelagem/gerar_logico.py`
