import re

file_path = "frontend/src/pages/DossierDetail.jsx"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Update metadataForm state
new_state = """    // Mariage
    nom_epoux: '', profession_epoux: '', domicile_epoux: '', date_naissance_epoux: '', lieu_naissance_epoux: '', prenom_pere_epoux: '', prenom_mere_epoux: '',
    nom_epouse: '', profession_epouse: '', domicile_epouse: '', date_naissance_epouse: '', lieu_naissance_epouse: '', prenom_pere_epouse: '', prenom_mere_epouse: '',
    date_marriage: '', option_souscrite: '', regime_matrimonial: '', annee_marriage: '', registre_marriage: '',"""
content = re.sub(r'// Mariage.*registre_marriage: \'\',', new_state, content, flags=re.DOTALL)

# 2. Update handleOpenEdit mapping
new_mapping = """      nom_epoux: dossier.metadata?.nom_epoux || '',
      profession_epoux: dossier.metadata?.profession_epoux || '',
      domicile_epoux: dossier.metadata?.domicile_epoux || '',
      date_naissance_epoux: dossier.metadata?.date_naissance_epoux || '',
      lieu_naissance_epoux: dossier.metadata?.lieu_naissance_epoux || '',
      prenom_pere_epoux: dossier.metadata?.prenom_pere_epoux || '',
      prenom_mere_epoux: dossier.metadata?.prenom_mere_epoux || '',
      nom_epouse: dossier.metadata?.nom_epouse || '',
      profession_epouse: dossier.metadata?.profession_epouse || '',
      domicile_epouse: dossier.metadata?.domicile_epouse || '',
      date_naissance_epouse: dossier.metadata?.date_naissance_epouse || '',
      lieu_naissance_epouse: dossier.metadata?.lieu_naissance_epouse || '',
      prenom_pere_epouse: dossier.metadata?.prenom_pere_epouse || '',
      prenom_mere_epouse: dossier.metadata?.prenom_mere_epouse || '',
      date_marriage: dossier.metadata?.date_marriage || '',
      option_souscrite: dossier.metadata?.option_souscrite || '',
      regime_matrimonial: dossier.metadata?.regime_matrimonial || '',
      annee_marriage: dossier.metadata?.annee_marriage || '',
      registre_marriage: dossier.metadata?.registre_marriage || '',
"""
# We just insert it in handleOpenEdit
content = content.replace("nom_mere: dossier.metadata?.nom_mere || '',", "nom_mere: dossier.metadata?.nom_mere || '',\n" + new_mapping)

# 3. Update InfoRow display
new_display = """                  <div className="mb-2">
                    <p className="text-xs font-semibold text-primary mb-1 uppercase">L'Époux</p>
                    <InfoRow label="Nom" value={dossier.metadata?.nom_epoux} />
                    <InfoRow label="Profession" value={dossier.metadata?.profession_epoux} />
                    <InfoRow label="Né(e) le" value={dossier.metadata?.date_naissance_epoux} />
                    <InfoRow label="Lieu" value={dossier.metadata?.lieu_naissance_epoux} />
                  </div>
                  <div className="mb-2">
                    <p className="text-xs font-semibold text-primary mb-1 uppercase mt-3">L'Épouse</p>
                    <InfoRow label="Nom" value={dossier.metadata?.nom_epouse} />
                    <InfoRow label="Profession" value={dossier.metadata?.profession_epouse} />
                    <InfoRow label="Né(e) le" value={dossier.metadata?.date_naissance_epouse} />
                    <InfoRow label="Lieu" value={dossier.metadata?.lieu_naissance_epouse} />
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-primary mb-1 uppercase mt-3">Le Mariage</p>
                    <InfoRow label="Date" value={dossier.metadata?.date_marriage} />
                    <InfoRow label="Régime" value={dossier.metadata?.regime_matrimonial} />
                    <InfoRow label="Option" value={dossier.metadata?.option_souscrite} />
                    <InfoRow label="Registre" value={dossier.metadata?.registre_marriage + " (" + dossier.metadata?.annee_marriage + ")"} />
                  </div>"""
content = re.sub(r'<div className="mb-2">\s*<p className="text-xs font-semibold text-primary mb-1 uppercase">Époux</p>.*?</>', f"<>\n{new_display}\n</>", content, flags=re.DOTALL)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
print("Updated DossierDetail.jsx")
