-- Exécuté une seule fois, à la création du volume PostgreSQL.
-- La base principale est créée par POSTGRES_DB ; on ajoute la base des tests automatisés.
CREATE DATABASE nadorcare_test;

\connect nadorcare
CREATE EXTENSION IF NOT EXISTS postgis;

\connect nadorcare_test
CREATE EXTENSION IF NOT EXISTS postgis;
