-- 0. Création de l'utilisateur dédié
CREATE ROLE mmtmsbi WITH LOGIN PASSWORD 'mot_de_passe';

-- A reproduire sur chaque base avec le user : mmtms / mmtmsact / mmtmsitp / mmtmsirf

-- 1. Création du schéma 'bi' si nécessaire
CREATE SCHEMA IF NOT EXISTS bi
    AUTHORIZATION mmtms;

-- 2. Droits d'accès sur le schéma 'bi'
GRANT USAGE ON SCHEMA bi TO mmtmsbi;

-- Accès en lecture à toutes les vues existantes du schéma 'bi'
GRANT SELECT ON ALL TABLES IN SCHEMA bi TO mmtmsbi;

-- Attribution automatique des accès aux FUTURES vues du schéma 'bi'
ALTER DEFAULT PRIVILEGES IN SCHEMA bi 
GRANT SELECT ON TABLES TO mmtmsbi;
