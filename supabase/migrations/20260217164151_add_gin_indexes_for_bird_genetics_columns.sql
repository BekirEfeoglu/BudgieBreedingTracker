-- GIN indexes for JSONB columns to optimize genetics-related queries
-- GIN is ideal for JSONB containment (@>) and existence (?) operators

CREATE INDEX IF NOT EXISTS idx_birds_mutations_gin ON birds USING GIN (mutations);
CREATE INDEX IF NOT EXISTS idx_birds_genotype_info_gin ON birds USING GIN (genotype_info);;
