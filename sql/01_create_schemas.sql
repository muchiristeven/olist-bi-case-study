/*
============================================================
OLIST E-COMMERCE BUSINESS INTELLIGENCE CASE STUDY
01 - Database Schema Setup
============================================================

Purpose:
Create the database schemas used to separate raw source data,
data preparation logic, and analytics-ready tables.

Database: PostgreSQL
============================================================
*/

CREATE SCHEMA IF NOT EXISTS raw;

CREATE SCHEMA IF NOT EXISTS staging;

CREATE SCHEMA IF NOT EXISTS analytics;
