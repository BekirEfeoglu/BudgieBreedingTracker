-- Phase 25: Add mutations and genotype_info columns to birds table
-- mutations: JSON-encoded list of mutation IDs (e.g., ['blue', 'opaline'])
-- genotype_info: JSON-encoded map of mutationId -> alleleState (e.g., {'blue': 'visual'})

ALTER TABLE birds ADD COLUMN mutations jsonb DEFAULT NULL;
ALTER TABLE birds ADD COLUMN genotype_info jsonb DEFAULT NULL;;
