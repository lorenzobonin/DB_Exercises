-- Query 1: elencare tutte le ragazze iscritte a ingegneria.
SELECT *
FROM studenti
WHERE matricola LIKE "IN%" AND 
(cf LIKE "_________4%" OR cf LIKE "_________5%" OR cf LIKE "_________6%" OR cf LIKE "_________7%");

SELECT *
FROM studenti
WHERE matricola LIKE "IN%" AND 
SUBSTRING(cf,10,1) IN ("4","5","6","7");

SELECT *
FROM studenti
WHERE matricola LIKE "IN%" AND 
SUBSTRING(cf,10,1) BETWEEN "4" AND "7";


-- Query 1: modifica al DB
ALTER TABLE studenti
ADD COLUMN genere CHAR(1) NOT NULL;

SET SQL_SAFE_UPDATES=0;

UPDATE studenti SET genere="M";

UPDATE studenti SET genere="F"
WHERE SUBSTRING(cf,10,1) BETWEEN "4" AND "7";

SET SQL_SAFE_UPDATES=1;

ALTER TABLE studenti
ADD CHECK (genere IN ("M", "F"));

SELECT *
FROM studenti
WHERE matricola LIKE "IN%" AND genere="F";


-- Query 2: quanti studenti hanno preso una lode negli esami del prof. De Lorenzo?
SELECT COUNT(DISTINCT e.studente) as n_lodati
FROM esami e INNER JOIN corsi c 
ON e.corso = c.codice
    INNER JOIN professori p 
    ON c.professore = p.matricola
WHERE e.lode=TRUE AND p.cognome="De Lorenzo";


-- Query 3: quali studenti hanno preso più di una lode con il prof. De Lorenzo?
SELECT e.studente, COUNT(e.lode) as n_lodi
FROM esami e INNER JOIN corsi c 
ON e.corso = c.codice
    INNER JOIN professori p 
    ON c.professore = p.matricola
WHERE e.lode=TRUE AND p.cognome="De Lorenzo"
GROUP BY e.studente
HAVING n_lodi>=2;