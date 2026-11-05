/*
Trabalho Prático 01 - Gestão de Banco de Dados (PostgreSQL)
Banco de dados: Player One, plataforma de biblioteca de jogos

JUSTIFICATIVA DO TEMA
Escolhi o tema jogos porque os videogames sempre estiveram presentes na minha
vida, desde clássicos como GTA San Andreas, Minecraft e Fireboy and Watergirl
até jogos competitivos como CS2 e League of Legends. Como conheço bem esse
assunto, ficou mais fácil criar regras de negócio e dados coerentes. Também
dá para modelar bastante coisa: um jogo tem uma desenvolvedora e um gênero,
roda em várias plataformas (N:N) e é colecionado por vários jogadores (N:N),
com informações que pertencem à relação, como horas jogadas, nota e status.

CONTEXTUALIZAÇÃO DO NEGÓCIO
A Player One é uma plataforma digital onde os jogadores cadastram e organizam
a sua biblioteca de jogos. Cada jogo pertence a uma desenvolvedora e a um
gênero e pode estar em uma ou mais plataformas. Para cada jogo que possui, o
jogador guarda a data em que adquiriu, o valor pago (jogo gratuito fica com
zero), as horas jogadas, uma nota de 1 a 5 e o status (não iniciado, jogando,
zerado ou abandonado). Com isso dá para saber quais jogos são mais jogados,
quanto cada jogador gastou, qual gênero tem a melhor nota e quais jogos estão
parados no backlog.

Tabelas: jogadores, desenvolvedoras, generos, plataformas, jogos,
jogos_plataformas e biblioteca.
*/


-- Apaga as tabelas antigas para o script poder ser rodado mais de uma vez
DROP TABLE IF EXISTS biblioteca CASCADE;
DROP TABLE IF EXISTS jogos_plataformas CASCADE;
DROP TABLE IF EXISTS jogos CASCADE;
DROP TABLE IF EXISTS plataformas CASCADE;
DROP TABLE IF EXISTS generos CASCADE;
DROP TABLE IF EXISTS desenvolvedoras CASCADE;
DROP TABLE IF EXISTS jogadores CASCADE;


-- ==========================================
-- CRIAÇÃO DAS TABELAS
-- ==========================================

-- jogadores: guarda quem usa a plataforma. Cada jogador tem nickname e email
-- próprios e é dono de uma biblioteca de jogos.
CREATE TABLE jogadores (
    id_jogador SERIAL PRIMARY KEY,
    nickname VARCHAR(30) NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    cidade VARCHAR(60) NOT NULL DEFAULT 'Passos',
    data_cadastro DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT ck_jogadores_email CHECK (email LIKE '%_@_%._%')
);

-- desenvolvedoras: empresas ou comunidades que criaram os jogos. Serve para
-- agrupar os jogos por criador.
CREATE TABLE desenvolvedoras (
    id_desenvolvedora SERIAL PRIMARY KEY,
    nome VARCHAR(80) NOT NULL UNIQUE,
    pais VARCHAR(40) NOT NULL,
    ano_fundacao SMALLINT NOT NULL,
    CONSTRAINT ck_desenvolvedoras_ano CHECK (ano_fundacao BETWEEN 1950 AND 2026)
);

-- generos: lista dos gêneros (FPS, MOBA, Sandbox...). Assim não preciso
-- repetir o texto em cada jogo e consigo comparar gêneros nas consultas.
CREATE TABLE generos (
    id_genero SERIAL PRIMARY KEY,
    nome VARCHAR(40) NOT NULL UNIQUE,
    descricao VARCHAR(200)
);

-- plataformas: onde os jogos rodam (PC, PlayStation, Xbox, Mobile), separadas
-- por tipo.
CREATE TABLE plataformas (
    id_plataforma SERIAL PRIMARY KEY,
    nome VARCHAR(40) NOT NULL UNIQUE,
    tipo VARCHAR(10) NOT NULL,
    CONSTRAINT ck_plataformas_tipo CHECK (tipo IN ('PC', 'CONSOLE', 'MOBILE'))
);

-- jogos: cadastro principal dos jogos. Cada um pertence a uma desenvolvedora
-- e a um gênero, e tem classificação indicativa, modo de jogo e preço (jogo
-- gratuito tem preço zero).
CREATE TABLE jogos (
    id_jogo SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL UNIQUE,
    id_desenvolvedora INTEGER NOT NULL,
    id_genero INTEGER NOT NULL,
    ano_lancamento SMALLINT NOT NULL,
    classificacao_indicativa SMALLINT NOT NULL DEFAULT 0,
    modo_jogo VARCHAR(15) NOT NULL DEFAULT 'SINGLEPLAYER',
    preco NUMERIC(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_jogos_desenvolvedora FOREIGN KEY (id_desenvolvedora)
        REFERENCES desenvolvedoras (id_desenvolvedora),
    CONSTRAINT fk_jogos_genero FOREIGN KEY (id_genero)
        REFERENCES generos (id_genero),
    CONSTRAINT ck_jogos_ano CHECK (ano_lancamento BETWEEN 1970 AND 2027),
    CONSTRAINT ck_jogos_class CHECK (classificacao_indicativa IN (0, 10, 12, 14, 16, 18)),
    CONSTRAINT ck_jogos_modo CHECK (modo_jogo IN ('SINGLEPLAYER', 'MULTIPLAYER', 'AMBOS')),
    CONSTRAINT ck_jogos_preco CHECK (preco >= 0)
);

-- jogos_plataformas: tabela de ligação entre jogos e plataformas (N:N).
-- Diz em quais plataformas cada jogo está disponível.
CREATE TABLE jogos_plataformas (
    id_jogo INTEGER NOT NULL,
    id_plataforma INTEGER NOT NULL,
    PRIMARY KEY (id_jogo, id_plataforma),
    FOREIGN KEY (id_jogo) REFERENCES jogos (id_jogo) ON DELETE CASCADE,
    FOREIGN KEY (id_plataforma) REFERENCES plataformas (id_plataforma) ON DELETE CASCADE
);

-- biblioteca: tabela de ligação entre jogadores e jogos (N:N). Guarda os jogos
-- de cada jogador com a data de compra, valor pago, horas jogadas, nota
-- (opcional, de 1 a 5) e o status.
CREATE TABLE biblioteca (
    id_jogador INTEGER NOT NULL,
    id_jogo INTEGER NOT NULL,
    data_aquisicao DATE NOT NULL DEFAULT CURRENT_DATE,
    valor_pago NUMERIC(10,2) NOT NULL DEFAULT 0,
    horas_jogadas NUMERIC(8,1) NOT NULL DEFAULT 0,
    avaliacao SMALLINT,
    status VARCHAR(15) NOT NULL DEFAULT 'NAO_INICIADO',
    PRIMARY KEY (id_jogador, id_jogo),
    FOREIGN KEY (id_jogador) REFERENCES jogadores (id_jogador) ON DELETE CASCADE,
    FOREIGN KEY (id_jogo) REFERENCES jogos (id_jogo),
    CONSTRAINT ck_bib_valor CHECK (valor_pago >= 0),
    CONSTRAINT ck_bib_horas CHECK (horas_jogadas >= 0),
    CONSTRAINT ck_bib_avaliacao CHECK (avaliacao IS NULL OR avaliacao BETWEEN 1 AND 5),
    CONSTRAINT ck_bib_status CHECK (status IN ('NAO_INICIADO', 'JOGANDO', 'ZERADO', 'ABANDONADO')),
    -- jogo não iniciado não pode ter horas jogadas
    CONSTRAINT ck_bib_coerencia CHECK (status <> 'NAO_INICIADO' OR horas_jogadas = 0)
);


-- ==========================================

-- INSERÇÃO DOS DADOS

-- (dados de jogadores, horas, notas e preços são fictícios)
INSERT INTO jogadores (nickname, nome, email, cidade, data_cadastro) VALUES
('carlos_gamer', 'Carlos Eduardo Ribeiro', 'carlos.ribeiro@email.com', 'Passos', '2025-01-05'),
('fer_lima', 'Fernanda Lima Souza', 'fernanda.souza@email.com', 'Passos', '2025-02-14'),
('jp_almeida', 'João Pedro Almeida', 'joao.almeida@email.com', 'Fortaleza de Minas', '2025-05-20'),
('mari_pinto', 'Mariana Costa Pinto', 'mariana.pinto@email.com', 'Passos', '2025-08-10'),
('ricardo_n', 'Ricardo Nogueira', 'ricardo.n@email.com', 'São João Batista do Glória', '2025-09-08'),
('pati_mendes', 'Patrícia Mendes', 'patricia.mendes@email.com', 'Passos', '2026-01-15'),
('anderson_b', 'Anderson Barbosa', 'anderson.barbosa@email.com', 'Alpinópolis', '2026-03-04'),
('lu_ferreira', 'Luciana Ferreira', 'luciana.ferreira@email.com', 'Passos', '2026-07-30');

INSERT INTO desenvolvedoras (nome, pais, ano_fundacao) VALUES
('Valve', 'Estados Unidos', 1996),
('Riot Games', 'Estados Unidos', 2006),
('Mojang Studios', 'Suécia', 2009),
('Rockstar North', 'Reino Unido', 1987),
('Traveller''s Tales', 'Reino Unido', 1989),
('Electronic Arts', 'Estados Unidos', 1982),
('Santa Monica Studio', 'Estados Unidos', 1999),
('Comunidade Bomba Patch', 'Brasil', 2003),
('Oslo Albert', 'Estados Unidos', 2009);

INSERT INTO generos (nome, descricao) VALUES
('FPS', 'Tiro em primeira pessoa'),
('MOBA', 'Arena de batalha online em equipes'),
('Sandbox', 'Mundo aberto de construção e exploração livres'),
('Mundo Aberto', 'Ação em cidades abertas com missões e liberdade de exploração'),
('Esporte', 'Simuladores de esportes, como o futebol'),
('Ação e Aventura', 'Narrativa, combate e exploração'),
('Puzzle', 'Quebra-cabeças e desafios de lógica');

INSERT INTO plataformas (nome, tipo) VALUES
('PC', 'PC'),
('PlayStation', 'CONSOLE'),
('Xbox', 'CONSOLE'),
('Mobile', 'MOBILE');

INSERT INTO jogos (titulo, id_desenvolvedora, id_genero, ano_lancamento, classificacao_indicativa, modo_jogo, preco) VALUES
('Counter-Strike 2', 1, 1, 2023, 16, 'MULTIPLAYER', 0.00),
('League of Legends', 2, 2, 2009, 12, 'MULTIPLAYER', 0.00),
('Minecraft', 3, 3, 2011, 10, 'AMBOS', 99.90),
('GTA San Andreas', 4, 4, 2004, 18, 'SINGLEPLAYER', 49.90),
('GTA V', 4, 4, 2013, 18, 'AMBOS', 89.90),
('LEGO Marvel Super Heroes', 5, 6, 2013, 10, 'AMBOS', 59.90),
('FIFA 23', 6, 5, 2022, 0, 'AMBOS', 199.90),
('God of War', 7, 6, 2018, 18, 'SINGLEPLAYER', 149.90),
('Bomba Patch', 8, 5, 2004, 0, 'AMBOS', 0.00),
('Fireboy and Watergirl', 9, 7, 2009, 0, 'AMBOS', 0.00);

INSERT INTO jogos_plataformas (id_jogo, id_plataforma) VALUES
(1, 1),
(2, 1),
(3, 1), (3, 2), (3, 3), (3, 4),
(4, 1), (4, 2), (4, 3), (4, 4),
(5, 1), (5, 2), (5, 3),
(6, 1), (6, 2), (6, 3),
(7, 1), (7, 2), (7, 3),
(8, 1), (8, 2),
(9, 1), (9, 2),
(10, 1), (10, 4);

INSERT INTO biblioteca (id_jogador, id_jogo, data_aquisicao, valor_pago, horas_jogadas, avaliacao, status) VALUES
(1, 1, '2025-01-10', 0.00, 850.5, 5, 'JOGANDO'),
(1, 2, '2025-01-12', 0.00, 320.0, 4, 'JOGANDO'),
(1, 3, '2025-02-01', 99.90, 410.0, 5, 'JOGANDO'),
(1, 4, '2025-03-05', 49.90, 95.0, 5, 'ZERADO'),
(1, 10, '2025-03-10', 0.00, 18.0, 5, 'ZERADO'),
(2, 3, '2025-04-02', 99.90, 150.0, 5, 'JOGANDO'),
(2, 5, '2025-04-20', 89.90, 230.5, 5, 'JOGANDO'),
(2, 7, '2025-05-15', 199.90, 120.0, 3, 'JOGANDO'),
(3, 9, '2025-06-01', 0.00, 600.0, 5, 'JOGANDO'),
(3, 7, '2025-06-03', 199.90, 180.0, 4, 'JOGANDO'),
(3, 1, '2025-07-07', 0.00, 400.0, 4, 'JOGANDO'),
(4, 8, '2025-08-18', 149.90, 45.0, 5, 'ZERADO'),
(4, 6, '2025-09-02', 59.90, 30.0, 4, 'ZERADO'),
(5, 2, '2025-09-10', 0.00, 70.0, 2, 'ABANDONADO'),
(5, 5, '2025-10-01', 89.90, 0.0, NULL, 'NAO_INICIADO'),
(6, 10, '2026-01-20', 0.00, 8.0, 4, 'ZERADO'),
(6, 6, '2026-02-14', 59.90, 22.0, 5, 'JOGANDO'),
(7, 4, '2026-03-10', 49.90, 60.0, 5, 'ZERADO'),
(7, 8, '2026-04-02', 149.90, 0.0, NULL, 'NAO_INICIADO'),
(4, 2, '2026-05-22', 0.00, 12.0, 3, 'ABANDONADO');


-- ==========================================

-- CONSULTAS

-- 1) Catálogo de jogos com desenvolvedora e gênero (JOIN)
SELECT j.titulo, d.nome AS desenvolvedora, g.nome AS genero,
       j.ano_lancamento, j.classificacao_indicativa AS classificacao,
       j.modo_jogo, j.preco
FROM jogos j
JOIN desenvolvedoras d ON d.id_desenvolvedora = j.id_desenvolvedora
JOIN generos g ON g.id_genero = j.id_genero
ORDER BY j.ano_lancamento, j.titulo;

-- 2) Em quantas e em quais plataformas cada jogo está (JOIN + GROUP BY)
SELECT j.titulo,
       COUNT(p.id_plataforma) AS qtd_plataformas,
       STRING_AGG(p.nome, ', ' ORDER BY p.nome) AS plataformas
FROM jogos j
JOIN jogos_plataformas jp ON jp.id_jogo = j.id_jogo
JOIN plataformas p ON p.id_plataforma = jp.id_plataforma
GROUP BY j.id_jogo, j.titulo
ORDER BY qtd_plataformas DESC, j.titulo;

-- 3) Jogos mais jogados: total de horas, quantidade de jogadores e nota média
SELECT j.titulo,
       COUNT(b.id_jogador) AS qtd_jogadores,
       SUM(b.horas_jogadas) AS total_horas,
       ROUND(AVG(b.avaliacao), 2) AS nota_media
FROM jogos j
JOIN biblioteca b ON b.id_jogo = j.id_jogo
GROUP BY j.id_jogo, j.titulo
ORDER BY total_horas DESC;

-- 4) Jogadores com 2 ou mais jogos na biblioteca (GROUP BY + HAVING)
SELECT jg.nickname,
       COUNT(b.id_jogo) AS qtd_jogos,
       SUM(b.valor_pago) AS total_investido,
       SUM(b.horas_jogadas) AS total_horas
FROM jogadores jg
JOIN biblioteca b ON b.id_jogador = jg.id_jogador
GROUP BY jg.id_jogador, jg.nickname
HAVING COUNT(b.id_jogo) >= 2
ORDER BY total_horas DESC;

-- 5) Nota média e horas por gênero (só conta quem avaliou, já que a nota é opcional)
SELECT g.nome AS genero,
       COUNT(b.avaliacao) AS qtd_avaliacoes,
       ROUND(AVG(b.avaliacao), 2) AS nota_media,
       SUM(b.horas_jogadas) AS total_horas
FROM generos g
JOIN jogos j ON j.id_genero = g.id_genero
JOIN biblioteca b ON b.id_jogo = j.id_jogo
WHERE b.avaliacao IS NOT NULL
GROUP BY g.id_genero, g.nome
ORDER BY nota_media DESC, total_horas DESC;

-- 6) Jogos gratuitos que têm modo multiplayer
SELECT titulo, ano_lancamento, modo_jogo
FROM jogos
WHERE preco = 0
  AND modo_jogo IN ('MULTIPLAYER', 'AMBOS')
ORDER BY ano_lancamento;

-- 7) Jogos 18+ que existem em console (DISTINCT para não repetir por plataforma)
SELECT DISTINCT j.titulo, d.nome AS desenvolvedora, j.preco
FROM jogos j
JOIN desenvolvedoras d ON d.id_desenvolvedora = j.id_desenvolvedora
JOIN jogos_plataformas jp ON jp.id_jogo = j.id_jogo
JOIN plataformas p ON p.id_plataforma = jp.id_plataforma
WHERE j.classificacao_indicativa = 18
  AND p.tipo = 'CONSOLE'
ORDER BY j.titulo;

-- 8) Jogadores que ainda não têm nenhum jogo (LEFT JOIN)
SELECT jg.nickname, jg.nome, jg.data_cadastro
FROM jogadores jg
LEFT JOIN biblioteca b ON b.id_jogador = jg.id_jogador
WHERE b.id_jogo IS NULL;

-- 9) Backlog: jogos comprados que não foram iniciados ou foram abandonados
SELECT jg.nickname, j.titulo, b.status, b.valor_pago, b.data_aquisicao
FROM biblioteca b
JOIN jogadores jg ON jg.id_jogador = b.id_jogador
JOIN jogos j ON j.id_jogo = b.id_jogo
WHERE b.status IN ('NAO_INICIADO', 'ABANDONADO')
ORDER BY b.data_aquisicao;

-- 10) Total gasto e horas jogadas por desenvolvedora
SELECT d.nome AS desenvolvedora,
       COUNT(DISTINCT j.id_jogo) AS jogos_na_biblioteca,
       SUM(b.valor_pago) AS total_gasto,
       SUM(b.horas_jogadas) AS total_horas
FROM desenvolvedoras d
JOIN jogos j ON j.id_desenvolvedora = d.id_desenvolvedora
JOIN biblioteca b ON b.id_jogo = j.id_jogo
GROUP BY d.id_desenvolvedora, d.nome
ORDER BY total_horas DESC;