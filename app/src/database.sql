CREATE TABLE links (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users NOT NULL,
    url TEXT CHECK (char_length(url) <= 2083) NOT NULL,
    slug VARCHAR(50) CHECK (char_length(url) > 0) UNIQUE NOT NULL,
    meta JSON DEFAULT '{}' NOT NULL,
    start_date TIMESTAMPTZ DEFAULT timezone('utc', now()) NOT NULL,
    end_date TIMESTAMPTZ DEFAULT timezone('utc', now() + interval '24 hour') NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now()) NOT NULL,
    inserted_at TIMESTAMPTZ DEFAULT timezone('utc', now()) NOT NULL
);

ALTER TABLE links ENABLE ROW LEVEL SECURITY;

-- Policies remain unchanged
-- Functions and triggers remain unchanged
create policy "Users can create their own links." on links for
insert
    with check (auth.uid() = user_id);

create policy "Users can only view their own links. " on links for
select
    using (auth.uid() = user_id);

create policy "Users can only update their own links." on links for
update
    using (auth.uid() = user_id);

create policy "Users can only delete their own links." on links for delete using (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION update_modified_column()   
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;   
END;
$$ language 'plpgsql';

CREATE TRIGGER update_customer_modtime BEFORE UPDATE ON links FOR EACH ROW EXECUTE PROCEDURE  update_modified_column();
