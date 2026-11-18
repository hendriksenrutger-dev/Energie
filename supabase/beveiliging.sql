-- =====================================================================
--  Beveiliging Supabase voor Energie Inzicht
--
--  Probleem: de tabellen energie_maanden en energie_instellingen hebben de
--  regel "allow all ... to public using (true)". Iedereen met het adres en
--  de openbare sleutel uit de app kan alle energiegegevens lezen, wijzigen
--  en wissen, zonder in te loggen. De persoonlijke code beveiligt niets.
--
--  Oplossing: alleen ingelogde gebruikers op de lijst
--  public.toegestane_gebruikers (gemaakt met beveiliging.sql van Cucina).
--
--  VOLGORDE - belangrijk:
--   1. Eerst de nieuwe versie van de Energie-app live (met inloggen).
--   2. Open Energie op je telefoon en controleer dat je gegevens er staan
--      en dat je een maand kunt opslaan.
--   3. Pas dan dit script uitvoeren (Supabase -> SQL Editor).
--  Voer je het eerder uit, dan ziet de oude app geen gegevens meer.
-- =====================================================================


-- STAP 1 - Controle (verandert niets) ------------------------------------
-- Hier moet jouw e-mailadres staan. Staat er niets: eerst stap 1 van het
-- Cucina-script uitvoeren.
select u.email from public.toegestane_gebruikers t join auth.users u on u.id = t.user_id;


-- STAP 2 - Afschermen ------------------------------------------------------
do $$
begin
  if to_regprocedure('public.is_toegestaan()') is null then
    raise exception 'Functie is_toegestaan() ontbreekt: voer eerst beveiliging.sql van Cucina uit.';
  end if;
  if not exists (select 1 from public.toegestane_gebruikers) then
    raise exception 'De lijst toegestane_gebruikers is leeg: anders sluit je jezelf buiten.';
  end if;
end $$;

drop policy if exists "allow all energie_maanden" on public.energie_maanden;
drop policy if exists "allow all energie_instellingen" on public.energie_instellingen;
alter table public.energie_maanden enable row level security;
alter table public.energie_instellingen enable row level security;

drop policy if exists alleen_huishouden on public.energie_maanden;
drop policy if exists alleen_huishouden on public.energie_instellingen;
create policy alleen_huishouden on public.energie_maanden for all to authenticated
  using (public.is_toegestaan()) with check (public.is_toegestaan());
create policy alleen_huishouden on public.energie_instellingen for all to authenticated
  using (public.is_toegestaan()) with check (public.is_toegestaan());


-- STAP 3 - Testen ----------------------------------------------------------
-- Open Energie op je telefoon: je gegevens moeten er staan en opslaan moet werken.


-- ONGEDAAN MAKEN (alleen als er iets misgaat) -----------------------------
-- drop policy if exists alleen_huishouden on public.energie_maanden;
-- drop policy if exists alleen_huishouden on public.energie_instellingen;
-- create policy "allow all energie_maanden" on public.energie_maanden for all to public using (true) with check (true);
-- create policy "allow all energie_instellingen" on public.energie_instellingen for all to public using (true) with check (true);
