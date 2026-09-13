NOCTA RP — portail propre

1. Ouvre index.html.
2. Dans le bloc CONFIG, remplace YOUR_SUPABASE_URL et YOUR_SUPABASE_PUBLISHABLE_KEY.
3. Dans Supabase, exécute setup.sql après ton schéma actuel.
4. Dans Storage, crée un bucket PUBLIC nommé exactement `rp-videos`.
5. Le portail utilise l'auth Supabase, les profils, whitelist, documents fictifs, chat, news et vidéos.

IMPORTANT :
- Ne mets jamais une clé sb_secret_ ou service_role dans index.html.
- Les documents sont fictifs.
- Le système de whitelist ne sert pas à contourner des restrictions d'âge.
- Les vidéos sont en attente de modération avant publication.
