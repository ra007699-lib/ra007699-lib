/*
Trabalho 02 - Functions no PostgreSQL
Banco: Player One (biblioteca de jogos)

Antes de rodar esse arquivo tem que rodar o script do trabalho 01, porque as
functions usam as tabelas e os dados que foram criados lá.

Funções:
1. retorna_perfil_jogador
2. rt_total_investido
3. adicionar_jogo_biblioteca
4. marcar_abandonados
5. resumo_biblioteca_jogador
*/


-- FUNCTION 1
-- Mostra o perfil do jogador de acordo com as horas que ele jogou no total.
-- 1000h ou mais é hardcore, 300h ou mais é dedicado, menos que isso é casual.
-- Se o id não existir eu uso o FOUND pra devolver uma mensagem.
CREATE OR REPLACE FUNCTION retorna_perfil_jogador(p_id_jogador INT)
RETURNS TEXT AS $$
DECLARE
    v_nickname TEXT;
    v_horas NUMERIC;
BEGIN
    SELECT nickname INTO v_nickname
    FROM jogadores
    WHERE id_jogador = p_id_jogador;

    IF NOT FOUND THEN
        RETURN 'Jogador não encontrado!';
    END IF;

    -- se o jogador não tem jogo nenhum a soma dá NULL, por isso o COALESCE
    SELECT COALESCE(SUM(horas_jogadas), 0) INTO v_horas
    FROM biblioteca
    WHERE id_jogador = p_id_jogador;

    IF v_horas >= 1000 THEN
        RETURN v_nickname || ' - Perfil Hardcore (' || v_horas || ' h)';
    ELSIF v_horas >= 300 THEN
        RETURN v_nickname || ' - Perfil Dedicado (' || v_horas || ' h)';
    ELSIF v_horas > 0 THEN
        RETURN v_nickname || ' - Perfil Casual (' || v_horas || ' h)';
    ELSE
        RETURN v_nickname || ' - Ainda não jogou nada';
    END IF;
END;
$$ LANGUAGE plpgsql;


-- FUNCTION 2
-- Retorna quanto o jogador já gastou comprando jogos.
-- Quando ele não comprou nada o SUM vem NULL, então troco por 0 com o COALESCE.
CREATE OR REPLACE FUNCTION rt_total_investido(p_id_jogador INT)
RETURNS NUMERIC(10, 2) AS $$
DECLARE
    v_total NUMERIC(10, 2);
BEGIN
    SELECT SUM(valor_pago) INTO v_total
    FROM biblioteca
    WHERE id_jogador = p_id_jogador;

    RETURN COALESCE(v_total, 0.00);
END;
$$ LANGUAGE plpgsql;


-- FUNCTION 3
-- Faz a compra de um jogo pro jogador. Primeiro verifica se o jogador existe,
-- se o jogo existe e se ele já não tem o jogo. Se estiver tudo certo insere na
-- biblioteca com o preço atual do jogo, data de hoje e status NAO_INICIADO.
CREATE OR REPLACE FUNCTION adicionar_jogo_biblioteca(p_id_jogador INT, p_id_jogo INT)
RETURNS TEXT AS $$
DECLARE
    v_titulo VARCHAR(100);
    v_preco NUMERIC(10, 2);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM jogadores WHERE id_jogador = p_id_jogador) THEN
        RETURN 'Erro: jogador não encontrado.';
    END IF;

    SELECT titulo, preco INTO v_titulo, v_preco
    FROM jogos
    WHERE id_jogo = p_id_jogo;

    IF NOT FOUND THEN
        RETURN 'Erro: jogo não encontrado.';
    END IF;

    IF EXISTS (SELECT 1 FROM biblioteca
               WHERE id_jogador = p_id_jogador AND id_jogo = p_id_jogo) THEN
        RETURN 'Erro: o jogador já possui o jogo ' || v_titulo || '.';
    END IF;

    INSERT INTO biblioteca (id_jogador, id_jogo, data_aquisicao, valor_pago,
                            horas_jogadas, avaliacao, status)
    VALUES (p_id_jogador, p_id_jogo, CURRENT_DATE, v_preco, 0, NULL, 'NAO_INICIADO');

    RETURN v_titulo || ' adicionado à biblioteca por R$ ' || v_preco;
END;
$$ LANGUAGE plpgsql;


-- FUNCTION 4
-- Pega os jogos que o jogador comprou e nunca abriu (NAO_INICIADO) há mais de
-- p_dias dias e muda o status pra ABANDONADO. Usei um FOR com LOOP pra passar
-- por cada um e um cursor com parâmetro pra buscar o título do jogo e mostrar
-- no aviso. No final retorna quantos jogos foram alterados.
CREATE OR REPLACE FUNCTION marcar_abandonados(p_dias INT)
RETURNS INTEGER AS $$
DECLARE
    v_qtd INTEGER := 0;
    v_titulo VARCHAR(100);
    reg RECORD;
    cr_titulo CURSOR (p_id_jogo INTEGER) FOR
        SELECT titulo FROM jogos WHERE id_jogo = p_id_jogo;
BEGIN
    IF p_dias < 0 THEN
        RAISE EXCEPTION 'A quantidade de dias não pode ser negativa';
    END IF;

    FOR reg IN
        SELECT id_jogador, id_jogo
        FROM biblioteca
        WHERE status = 'NAO_INICIADO'
          AND data_aquisicao <= CURRENT_DATE - p_dias
    LOOP
        OPEN cr_titulo(reg.id_jogo);
        FETCH cr_titulo INTO v_titulo;
        CLOSE cr_titulo;

        UPDATE biblioteca
        SET status = 'ABANDONADO'
        WHERE id_jogador = reg.id_jogador
          AND id_jogo = reg.id_jogo;

        v_qtd := v_qtd + 1;
        RAISE NOTICE 'Jogo "%" do jogador % marcado como abandonado', v_titulo, reg.id_jogador;
    END LOOP;

    RETURN v_qtd;
END;
$$ LANGUAGE plpgsql;


-- FUNCTION 5
-- Relatório da biblioteca de um jogador: título, gênero, status, horas e nota,
-- começando pelo jogo que ele mais jogou. Pra chamar usa SELECT * FROM.
CREATE OR REPLACE FUNCTION resumo_biblioteca_jogador(p_id_jogador INT)
RETURNS TABLE (
    r_titulo VARCHAR,
    r_genero VARCHAR,
    r_status VARCHAR,
    r_horas NUMERIC,
    r_nota SMALLINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT j.titulo, g.nome, b.status, b.horas_jogadas, b.avaliacao
    FROM biblioteca b
    JOIN jogos j ON j.id_jogo = b.id_jogo
    JOIN generos g ON g.id_genero = j.id_genero
    WHERE b.id_jogador = p_id_jogador
    ORDER BY b.horas_jogadas DESC;
END;
$$ LANGUAGE plpgsql;


-- TESTES

-- function 1 (id existente, id que não existe, e todos os jogadores)
SELECT retorna_perfil_jogador(1);
SELECT retorna_perfil_jogador(99);
SELECT retorna_perfil_jogador(8);
SELECT j.nickname, retorna_perfil_jogador(j.id_jogador) AS perfil
FROM jogadores j
ORDER BY j.id_jogador;

-- function 2 (usando dentro de um select)
SELECT nickname, rt_total_investido(id_jogador) AS total_investido
FROM jogadores
ORDER BY total_investido DESC;

-- function 3 (a primeira chamada insere de verdade na biblioteca)
SELECT adicionar_jogo_biblioteca(8, 3);
SELECT adicionar_jogo_biblioteca(8, 3);   -- repetido, tem que dar erro
SELECT adicionar_jogo_biblioteca(99, 1);  -- jogador não existe
SELECT adicionar_jogo_biblioteca(1, 99);  -- jogo não existe

-- function 4 (altera os dados, e o resultado depende do dia que for rodado)
SELECT marcar_abandonados(180);
SELECT id_jogador, id_jogo, status FROM biblioteca
WHERE status IN ('NAO_INICIADO', 'ABANDONADO');

-- function 5
SELECT * FROM resumo_biblioteca_jogador(1);
SELECT * FROM resumo_biblioteca_jogador(4);