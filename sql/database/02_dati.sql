-- =====================================================================
--  DATI DI ESEMPIO
-- =====================================================================
--  Casi particolari inseriti apposta (ti serviranno negli esercizi):
--   - la categoria "Giochi" non ha nessun prodotto
--   - il prodotto "Gift card" non ha categoria (categoria_id NULL)
--   - "Webcam HD" e "Zaino da trekking" non sono mai stati ordinati
--   - "Manuale di SQL" ha scorta 0
--   - i clienti 10, 11, 14 non hanno mai fatto ordini
--   - il cliente 13 ha fatto solo un ordine, poi annullato
--   - i clienti 9 e 14 non hanno la città (NULL)
--   - ci sono due clienti di cognome Rossi
--   - l'ordine 31 non contiene ancora nessuna riga
--   - alcuni ordini sono stati fatti online (dipendente_id NULL)
--   - in alcune righe il prezzo pagato è diverso dal listino (sconti)
--   - la dipendente 1 (CEO) non ha responsabile; la gerarchia ha 4 livelli
--   - due recensioni sono di clienti che NON hanno comprato quel prodotto
--     (la 8, di una cliente senza ordini, e la 10, su un prodotto mai venduto)
-- =====================================================================

INSERT INTO categorie (id, nome) VALUES
    (1, 'Informatica'),
    (2, 'Libri'),
    (3, 'Casa'),
    (4, 'Sport'),
    (5, 'Giochi');

INSERT INTO prodotti (id, nome, categoria_id, prezzo, scorta) VALUES
    (1,  'Laptop Pro 14',         1, 1299.00,   5),
    (2,  'Mouse wireless',        1,   25.90, 120),
    (3,  'Tastiera meccanica',    1,   89.00,  40),
    (4,  'Monitor 27"',           1,  249.00,  15),
    (5,  'Cuffie Bluetooth',      1,   79.90,  60),
    (6,  'Il nome della rosa',    2,   14.50,  30),
    (7,  'Effective Java',        2,   45.00,  12),
    (8,  'Manuale di SQL',        2,   32.00,   0),
    (9,  'Caffettiera moka',      3,   29.90,  50),
    (10, 'Set pentole',           3,  119.00,   8),
    (11, 'Lampada da scrivania',  3,   34.50,  25),
    (12, 'Pallone da calcio',     4,   19.90,  70),
    (13, 'Tappetino yoga',        4,   24.00,  35),
    (14, 'Racchetta tennis',      4,   89.90,  10),
    (15, 'Borraccia termica',     4,   15.00, 100),
    (16, 'Gift card 50€',      NULL,   50.00, 999),
    (17, 'Webcam HD',             1,   59.00,  20),
    (18, 'Zaino da trekking',     4,   69.00,  15);

INSERT INTO clienti (id, nome, cognome, email, citta, data_registrazione) VALUES
    (1,  'Mario',      'Rossi',     'mario.rossi@example.com',       'Milano',   '2023-01-15'),
    (2,  'Giulia',     'Bianchi',   'giulia.bianchi@example.com',    'Roma',     '2023-02-20'),
    (3,  'Luca',       'Verdi',     'luca.verdi@example.com',        'Napoli',   '2023-03-05'),
    (4,  'Sara',       'Neri',      'sara.neri@example.com',         'Milano',   '2023-04-10'),
    (5,  'Paolo',      'Ferrari',   'paolo.ferrari@example.com',     'Torino',   '2023-05-22'),
    (6,  'Anna',       'Romano',    'anna.romano@example.com',       'Roma',     '2023-06-30'),
    (7,  'Marco',      'Colombo',   'marco.colombo@example.com',     'Milano',   '2023-09-12'),
    (8,  'Elena',      'Ricci',     'elena.ricci@example.com',       'Bologna',  '2023-11-03'),
    (9,  'Davide',     'Marino',    'davide.marino@example.com',      NULL,      '2024-01-08'),
    (10, 'Chiara',     'Greco',     'chiara.greco@example.com',      'Napoli',   '2024-02-14'),
    (11, 'Francesco',  'Bruno',     'francesco.bruno@example.com',   'Torino',   '2024-03-01'),
    (12, 'Martina',    'Gallo',     'martina.gallo@example.com',     'Firenze',  '2024-05-19'),
    (13, 'Alessandro', 'Conti',     'alessandro.conti@example.com',  'Roma',     '2024-07-07'),
    (14, 'Valentina',  'De Luca',   'valentina.deluca@example.com',   NULL,      '2024-09-21'),
    (15, 'Roberto',    'Costa',     'roberto.costa@example.com',     'Bologna',  '2024-11-11'),
    (16, 'Laura',      'Rossi',     'laura.rossi@example.com',       'Firenze',  '2025-01-20');

INSERT INTO dipendenti (id, nome, cognome, ruolo, reparto, responsabile_id, stipendio, data_assunzione) VALUES
    (1,  'Carla',     'Fontana',  'Amministratrice delegata', 'Direzione',  NULL, 6500, '2015-03-01'),
    (2,  'Giorgio',   'Moretti',  'Responsabile vendite',     'Vendite',       1, 4200, '2017-06-15'),
    (3,  'Silvia',    'Barbieri', 'Responsabile logistica',   'Logistica',     1, 4000, '2018-01-10'),
    (4,  'Andrea',    'Lombardi', 'Venditore',                'Vendite',       2, 2400, '2020-02-01'),
    (5,  'Federica',  'Rinaldi',  'Venditrice',               'Vendite',       2, 2500, '2019-09-01'),
    (6,  'Matteo',    'Caruso',   'Venditore',                'Vendite',       2, 2200, '2023-04-01'),
    (7,  'Irene',     'Ferraro',  'Magazziniera',             'Logistica',     3, 1900, '2021-07-01'),
    (8,  'Simone',    'Galli',    'Magazziniere',             'Logistica',     3, 1900, '2022-10-01'),
    (9,  'Tommaso',   'Mancini',  'Stagista',                 'Vendite',       4,  900, '2025-01-15'),
    (10, 'Beatrice',  'Longo',    'Analista',                 'Direzione',     1, 3100, '2020-05-01');

INSERT INTO ordini (id, cliente_id, dipendente_id, data_ordine, stato, spese_spedizione) VALUES
    (1,   1,    4, '2024-01-10', 'consegnato', 0),
    (2,   2,    5, '2024-01-22', 'consegnato', 4.90),
    (3,   1, NULL, '2024-02-05', 'consegnato', 0),
    (4,   3,    4, '2024-02-18', 'consegnato', 6.90),
    (5,   4,    6, '2024-03-03', 'consegnato', 0),
    (6,   5,    5, '2024-03-27', 'consegnato', 4.90),
    (7,   2, NULL, '2024-04-12', 'annullato',  4.90),
    (8,   6,    4, '2024-05-08', 'consegnato', 0),
    (9,   7,    5, '2024-05-30', 'consegnato', 0),
    (10,  1,    6, '2024-06-14', 'consegnato', 4.90),
    (11,  8, NULL, '2024-07-02', 'consegnato', 6.90),
    (12,  3,    5, '2024-07-19', 'consegnato', 0),
    (13,  9,    4, '2024-08-25', 'consegnato', 4.90),
    (14,  4, NULL, '2024-09-09', 'consegnato', 0),
    (15, 12,    6, '2024-10-15', 'consegnato', 6.90),
    (16,  2,    5, '2024-11-29', 'consegnato', 0),
    (17,  5,    4, '2024-11-29', 'consegnato', 0),
    (18, 13, NULL, '2024-12-05', 'annullato',  4.90),
    (19,  7,    5, '2024-12-18', 'consegnato', 0),
    (20,  1,    4, '2025-01-08', 'consegnato', 0),
    (21, 15,    6, '2025-01-25', 'consegnato', 6.90),
    (22,  6, NULL, '2025-02-14', 'consegnato', 4.90),
    (23,  8,    5, '2025-03-03', 'consegnato', 0),
    (24,  2,    4, '2025-03-21', 'spedito',    0),
    (25, 16, NULL, '2025-04-02', 'spedito',    4.90),
    (26, 12,    6, '2025-04-18', 'in_attesa',  0),
    (27,  3,    5, '2025-05-06', 'in_attesa',  6.90),
    (28,  9, NULL, '2025-05-20', 'in_attesa',  4.90),
    (29,  4,    4, '2025-06-01', 'in_attesa',  0),
    (30,  1,    5, '2025-06-10', 'annullato',  0),
    (31,  2, NULL, '2025-06-12', 'in_attesa',  0);

INSERT INTO righe_ordine (ordine_id, prodotto_id, quantita, prezzo_unitario) VALUES
    (1,  1, 1, 1299.00), (1,  2, 1,   25.90),
    (2,  6, 2,   14.50), (2,  9, 1,   29.90),
    (3,  3, 1,   89.00), (3,  5, 1,   79.90),
    (4, 12, 2,   19.90), (4, 15, 3,   15.00),
    (5,  4, 2,  249.00),
    (6,  7, 1,   45.00), (6,  8, 1,   32.00),
    (7, 10, 1,  119.00),
    (8, 13, 1,   24.00), (8, 15, 2,   15.00),
    (9,  1, 1, 1249.00), (9,  2, 2,   25.90),
    (10, 11, 2,  34.50),
    (11,  6, 1,  14.50), (11,  7, 1,  45.00), (11,  8, 1,  32.00),
    (12, 14, 1,  89.90), (12, 12, 1,  19.90),
    (13,  5, 1,  79.90),
    (14,  9, 2,  29.90), (14, 10, 1, 119.00),
    (15, 16, 2,  50.00),
    (16,  1, 1, 1099.00), (16,  3, 1,  69.00), (16,  5, 1,  59.90),
    (17,  4, 1, 199.00), (17,  2, 1,  19.90),
    (18, 14, 1,  89.90),
    (19, 13, 2,  24.00), (19, 12, 1,  19.90),
    (20,  7, 1,  45.00),
    (21,  1, 1, 1299.00), (21,  4, 1, 249.00),
    (22,  9, 1,  29.90), (22, 11, 1,  34.50),
    (23,  6, 3,  14.50),
    (24,  2, 2,  25.90), (24,  3, 1,  89.00),
    (25, 15, 4,  15.00),
    (26, 16, 1,  50.00),
    (27, 10, 1, 119.00),
    (28,  5, 1,  79.90), (28,  2, 1,  25.90),
    (29, 12, 3,  19.90), (29, 13, 1,  24.00),
    (30,  1, 1, 1299.00);
    -- l'ordine 31 non ha righe: è stato appena creato

INSERT INTO recensioni (id, prodotto_id, cliente_id, voto, commento, data) VALUES
    (1,   1,  1, 5, 'Velocissimo',        '2024-01-20'),
    (2,   2,  1, 4, NULL,                 '2024-01-20'),
    (3,   6,  2, 5, 'Un classico',        '2024-02-01'),
    (4,   9,  2, 3, 'Fa il suo lavoro',   '2024-02-03'),
    (5,   5,  1, 3, 'Batteria scarsa',    '2024-02-25'),
    (6,   4,  4, 4, NULL,                 '2024-03-15'),
    (7,   8,  5, 2, 'Troppo teorico',     '2024-04-10'),
    (8,  13, 10, 5, NULL,                 '2024-05-20'),
    (9,   1,  7, 4, 'Ottimo ma costoso',  '2024-06-10'),
    (10, 17,  1, 4, 'Immagine nitida',    '2024-06-30'),
    (11,  7,  8, 5, 'Imprescindibile',    '2024-07-15'),
    (12, 12,  3, 4, NULL,                 '2024-07-30'),
    (13,  5,  9, 2, NULL,                 '2024-09-01'),
    (14, 16, 12, 5, NULL,                 '2024-10-20'),
    (15,  1,  2, 5, NULL,                 '2024-12-10');
