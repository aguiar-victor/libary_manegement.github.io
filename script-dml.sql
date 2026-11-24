-- ============================================================================
-- SCRIPT DML - POVOAMENTO DO SISTEMA DE GERENCIAMENTO DE BIBLIOTECA
-- SGBD: MySQL 8.0+
-- Massa de dados ficticia, organizada em cenarios de operacao do negocio.
-- Execute este arquivo depois de script-ddl.sql.
-- ============================================================================

USE BibliotecaDB;

-- ---------------------------------------------------------------------------
-- CENARIO 1 - Preparacao da biblioteca e organizacao do acervo
-- Antes da abertura ao publico, a gerencia cadastra os funcionarios,
-- as categorias e os primeiros livros que estarao disponiveis para consulta.
-- ---------------------------------------------------------------------------

INSERT INTO Funcionario
(idFuncionario, nome, CPF, email, funcao, dataAdmissao, ativo)
VALUES
(1, 'Ana Souza',        '10120230304', 'ana.souza@bibliotecaexemplo.com',        'gerente',        '2024-02-01', 1),
(2, 'Paulo Lima',       '20220330405', 'paulo.lima@bibliotecaexemplo.com',       'recepcionista',  '2024-03-10', 1),
(3, 'Beatriz Costa',    '30340450506', 'beatriz.costa@bibliotecaexemplo.com',    'recepcionista',  '2024-06-15', 1),
(4, 'Marcos Nunes',     '40450560607', 'marcos.nunes@bibliotecaexemplo.com',     'recepcionista',  '2025-01-20', 1),
(5, 'Fernanda Alves',   '50560670708', 'fernanda.alves@bibliotecaexemplo.com',   'gerente',        '2025-04-05', 1);

INSERT INTO CategoriaLivro
(idCategoria, nome, descricao, ativo, dataCadastro)
VALUES
(1, 'Literatura brasileira', 'Romances e obras de autores brasileiros.', 1, '2026-09-01'),
(2, 'Literatura estrangeira', 'Obras literarias de autores de outros paises.', 1, '2026-09-01'),
(3, 'Infantil e juvenil', 'Livros destinados ao publico infantil e juvenil.', 1, '2026-09-01'),
(4, 'Ciencias e tecnologia', 'Conteudos de tecnologia, computacao e ciencias.', 1, '2026-09-01'),
(5, 'Historia e sociedade', 'Obras historicas, biografias e temas sociais.', 1, '2026-09-01');

INSERT INTO Livro
(idLivro, titulo, autor, ISBN, anoPublicacao, quantidadeEstoque, idCategoria)
VALUES
(10, 'O Pequeno Principe', 'Antoine de Saint-Exupery', '9780156012195', 1943, 5, 3),
(20, 'Dom Casmurro', 'Machado de Assis', '9788535902778', 1899, 4, 1),
(30, 'Capitaes da Areia', 'Jorge Amado', '9788535911695', 1937, 4, 1),
(40, 'Codigo Limpo', 'Robert C. Martin', '9788576082675', 2008, 3, 4),
(50, 'O Diario de Anne Frank', 'Anne Frank', '9788501044457', 1947, 1, 5);

-- ---------------------------------------------------------------------------
-- CENARIO 2 - Cadastro dos primeiros leitores
-- Na semana de inauguracao, cinco moradores se cadastram para utilizar
-- o acervo. Maria ja possui uma pendencia anterior e fica como inadimplente;
-- os demais iniciam com situacao regular.
-- ---------------------------------------------------------------------------

INSERT INTO Cliente
(idCliente, nome, CPF, telefone, email, logradouro, numero, bairro,
 cidade, uf, cep, situacao, dataCadastro)
VALUES
(1, 'Carlos Eduardo Silva', '11122233301', '84999990001', 'carlos.silva@email.com',
 'Rua das Flores', '120', 'Centro', 'Canguaretama', 'RN', '59190000', 'regular', '2026-09-28'),
(2, 'Maria Fernanda Oliveira', '22233344402', '84999990002', 'maria.oliveira@email.com',
 'Avenida Brasil', '150', 'Centro', 'Canguaretama', 'RN', '59190000', 'inadimplente', '2026-09-29'),
(3, 'Joao Pedro Santos', '33344455503', '84999990003', 'joao.santos@email.com',
 'Rua do Sol', '45', 'Areia Branca', 'Canguaretama', 'RN', '59190000', 'regular', '2026-10-01'),
(4, 'Luana Ribeiro', '44455566604', '84999990004', 'luana.ribeiro@email.com',
 'Rua Nova', '88', 'Estacao', 'Canguaretama', 'RN', '59190000', 'regular', '2026-10-02'),
(5, 'Rafael Martins', '55566677705', '84999990005', 'rafael.martins@email.com',
 'Travessa da Paz', '27', 'Centro', 'Canguaretama', 'RN', '59190000', 'regular', '2026-10-03');

-- ---------------------------------------------------------------------------
-- CENARIO 3 - Primeiras retiradas de livros
-- Em outubro, os leitores realizam cinco emprestimos. Cada operacao fica
-- vinculada ao cliente e ao funcionario que realizou o atendimento.
-- Os prazos iniciais foram definidos para aproximadamente um mes.
-- ---------------------------------------------------------------------------

INSERT INTO Emprestimo
(idEmprestimo, dataEmprestimo, dataLimiteDevolucao, dataProrrogacao,
 status, idCliente, idFuncionario)
VALUES
(101, '2026-10-01', '2026-11-01', NULL, 'finalizado',   1, 2),
(102, '2026-10-02', '2026-11-02', NULL, 'finalizado',   2, 3),
(103, '2026-10-05', '2026-11-05', '2026-11-20', 'em_andamento', 3, 2),
(104, '2026-10-06', '2026-11-06', NULL, 'finalizado',   4, 4),
(105, '2026-10-07', '2026-11-07', NULL, 'finalizado',   5, 3);

-- ---------------------------------------------------------------------------
-- CENARIO 4 - Atendimento das reservas
-- Tres reservas feitas antes ou no dia da retirada foram atendidas e ligadas
-- aos emprestimos correspondentes. Uma reserva continua ativa porque o
-- exemplar de Anne Frank esta emprestado; outra foi cancelada pelo leitor.
-- Este bloco vem depois de Emprestimo por causa da chave estrangeira opcional
-- que liga uma reserva atendida ao emprestimo gerado.
-- ---------------------------------------------------------------------------

INSERT INTO Reserva
(idReserva, idCliente, idLivro, idFuncionario, idEmprestimo,
 dataReserva, dataEncerramento, status, observacao)
VALUES
(1, 1, 10, 2, 101, '2026-09-29', '2026-10-01', 'atendida', 'Reserva atendida na retirada de O Pequeno Principe.'),
(2, 2, 30, 3, 102, '2026-10-01', '2026-10-02', 'atendida', 'Cliente retirou Capitaes da Areia.'),
(3, 3, 40, 2, 103, '2026-10-04', '2026-10-05', 'atendida', 'Reserva atendida para retirada de Codigo Limpo.'),
(4, 4, 50, 4, NULL, '2026-10-08', NULL, 'ativa', 'Aguardando a devolucao do unico exemplar disponivel.'),
(5, 5, 20, 3, NULL, '2026-10-09', '2026-10-10', 'cancelada', 'Leitor solicitou o cancelamento da reserva.');

-- ---------------------------------------------------------------------------
-- CENARIO 5 - Detalhamento dos exemplares e registro das devolucoes
-- O emprestimo 103 possui dois livros e foi prorrogado ate 20/11/2026.
-- Os demais itens ja foram devolvidos; alguns retornaram com atraso ou avaria.
-- ---------------------------------------------------------------------------

INSERT INTO ItemEmprestimo
(idEmprestimo, idLivro, quantidade, dataDevolucao, situacaoItem)
VALUES
(101, 10, 1, '2026-10-30', 'devolvido'),
(101, 20, 1, '2026-11-05', 'avariado'),
(102, 30, 1, '2026-11-10', 'devolvido'),
(103, 40, 1, '2026-11-06', 'avariado'),
(103, 50, 1, NULL,         'emprestado'),
(104, 30, 1, '2026-11-11', 'devolvido'),
(105, 10, 1, '2026-11-08', 'devolvido');

-- ---------------------------------------------------------------------------
-- CENARIO 6 - Registro e pagamento de multas
-- Durante a conferencia das devolucoes, a equipe registra ocorrencias por
-- avaria ou atraso. Algumas multas ja foram quitadas; as demais permanecem
-- pendentes para pagamento pelo leitor.
-- ---------------------------------------------------------------------------

INSERT INTO Multa
(idMulta, idEmprestimo, idLivro, idFuncionario, tipo, descricao,
 valor, dataRegistro, dataPagamento, statusPagamento)
VALUES
(1, 101, 20, 2, 'avaria', 'Capa e contracapa do livro danificadas.', 15.00, '2026-11-05', '2026-11-12', 'paga'),
(2, 102, 30, 3, 'atraso', 'Devolucao realizada oito dias apos o prazo.', 8.00, '2026-11-10', NULL, 'pendente'),
(3, 103, 40, 2, 'avaria', 'Duas paginas foram rasgadas durante o uso.', 20.00, '2026-11-06', '2026-11-15', 'paga'),
(4, 104, 30, 4, 'atraso', 'Devolucao realizada cinco dias apos o prazo.', 5.00, '2026-11-11', NULL, 'pendente'),
(5, 105, 10, 3, 'atraso', 'Devolucao realizada um dia apos o prazo.', 2.00, '2026-11-08', '2026-11-08', 'paga');

-- ---------------------------------------------------------------------------
-- CONFERENCIA DO POVOAMENTO
-- Cada uma das oito tabelas deve apresentar pelo menos cinco registros.
-- Execute este SELECT para conferir a quantidade inserida em cada tabela.
-- ---------------------------------------------------------------------------

SELECT 'CategoriaLivro' AS tabela, COUNT(*) AS quantidade FROM CategoriaLivro
UNION ALL
SELECT 'Cliente', COUNT(*) FROM Cliente
UNION ALL
SELECT 'Funcionario', COUNT(*) FROM Funcionario
UNION ALL
SELECT 'Livro', COUNT(*) FROM Livro
UNION ALL
SELECT 'Emprestimo', COUNT(*) FROM Emprestimo
UNION ALL
SELECT 'ItemEmprestimo', COUNT(*) FROM ItemEmprestimo
UNION ALL
SELECT 'Multa', COUNT(*) FROM Multa
UNION ALL
SELECT 'Reserva', COUNT(*) FROM Reserva;
