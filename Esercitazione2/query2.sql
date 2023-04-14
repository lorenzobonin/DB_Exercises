USE uni_db;


-- Query 4: quali studenti non hanno mai preso una lode?
SELECT * 
FROM studenti s
WHERE NOT EXISTS (
    SELECT *
    FROM esami e
    WHERE e.lode=TRUE AND 
    e.studente=s.matricola
);

SELECT * 
FROM studenti s
WHERE s.matricola NOT IN(
    SELECT DISTINCT studente
    FROM esami e
    WHERE e.lode=TRUE
);


-- Query 5: quali docenti svolgono un monte ore annuo minore di 120 ore?
SELECT p.nome, p.cognome, SUM(8*c.cfu) as monte_ore
FROM professori p
INNER JOIN corsi c
ON p.matricola = c.professore
GROUP BY c.professore
HAVING monte_ore<120;


-- Query 6: qual è la media ponderata di ogni studente?
SELECT s.matricola, s.nome, s.cognome, 
SUM(e.voto*c.cfu)/SUM(c.cfu) as media
FROM studenti s
INNER JOIN esami e 
ON s.matricola = e.studente
    INNER JOIN corsi c
    ON e.corso = c.codice
GROUP BY e.studente;

-- Query 7: verificare se ci sono casi di omonimia tra studenti e/o professori
SELECT nome, cognome, COUNT(*) AS c
FROM(
	SELECT nome, cognome
	FROM studenti
	UNION ALL
	SELECT nome, cognome
	FROM professori) AS t
GROUP BY nome, cognome
ORDER BY c DESC;

-- Prepared statement 1: creare uno statement che mostri tutti gli studenti di un corso di laurea passato come parametro
PREPARE studenti_cdl FROM
"SELECT * 
FROM studenti
WHERE matricola LIKE CONCAT(?,'%')";

SET @cdl = "IN05";
EXECUTE studenti_cdl USING @cdl;

-- Prepared statement 2: creare un prepared statement che mostri tutti gli studenti che hanno superato l’esame di un dato corso, il cui codice è passato come parametro.
PREPARE studenti_superato_corso FROM
" SELECT s.nome, s.cognome, s.matricola
FROM studenti s
INNER JOIN esami e
ON s.matricola = e.studente
WHERE e.corso = ?";

-- Vista 1: quali sono i voti preferiti di ogni professore?
CREATE VIEW dist_voti AS
SELECT p.matricola, p.nome, p.cognome, e.voto, COUNT(e.voto) as n_voti
FROM professori p
INNER JOIN corsi c ON p.matricola = c.professore
INNER JOIN esami e ON c.codice = e.corso
GROUP BY p.matricola, e.voto;

SELECT DISTINCT matricola, nome, cognome, voto
FROM dist_voti d1
WHERE n_voti = (
	SELECT MAX(n_voti)
	FROM dist_voti d2
	WHERE d1.matricola = d2.matricola
);

-- Vista 2: quali sono gli studenti più ”bravi” di ogni corso di laurea?
CREATE VIEW bravura_per_cdl AS
SELECT s.matricola, s.nome, s.cognome, SUBSTRING(s.matricola, 1, 4) as cdl, SUM(e.voto * c.cfu) as bravura
FROM studenti s
INNER JOIN esami e ON s.matricola = e.studente
INNER JOIN corsi c ON e.corso = c.codice
GROUP BY s.matricola;

SELECT DISTINCT matricola, nome, cognome, cdl
FROM bravura_per_cdl b1
WHERE bravura = (
	SELECT MAX(bravura)
	FROM bravura_per_cdl b2
	WHERE b1.cdl=b2.cdl
);