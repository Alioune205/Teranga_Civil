import os
import re

with open('frontend/src/components/citoyens/FormulaireRegularisation.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

jsx_fields = '''<div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Nom complet */}
        <div className="space-y-2 md:col-span-2">
          <label className="text-sm font-medium text-text-200">Nom complet *</label>
          <input
            type="text"
            name="nom_complet"
            value={formData.nom_complet}
            onChange={handleChange}
            className="w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
            placeholder="Ex : Amadou Ndiaye"
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Numéro CNI *</label>
          <input
            type="text"
            name="numero_cni"
            value={formData.numero_cni}
            onChange={handleChange}
            className="w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
            placeholder="Ex : 1234567890123"
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Téléphone *</label>
          <input
            type="text"
            name="telephone"
            value={formData.telephone}
            onChange={handleChange}
            className="w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
            placeholder="Ex : 77 123 45 67"
          />
        </div>
        <div className="space-y-2 md:col-span-2">
          <label className="text-sm font-medium text-text-200">Adresse</label>
          <input
            type="text"
            name="adresse"
            value={formData.adresse}
            onChange={handleChange}
            className="w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
          />
        </div>
        
        <div className="space-y-1 md:col-span-2 mt-4">
          <h4 className="text-sm font-semibold text-text-300 uppercase tracking-wider">
            Informations sur le terrain
          </h4>
          <div className="h-px bg-border-subtle" />
        </div>
        
        <div className="space-y-2 md:col-span-2">
          <label className="text-sm font-medium text-text-200">Localisation du terrain *</label>
          <input
            type="text"
            name="localisation_terrain"
            value={formData.localisation_terrain}
            onChange={handleChange}
            className="w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Quartier / Village</label>
          <input
            type="text"
            name="quartier_village"
            value={formData.quartier_village}
            onChange={handleChange}
            className="w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Superficie</label>
          <input
            type="text"
            name="superficie"
            value={formData.superficie}
            onChange={handleChange}
            className="w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
            placeholder="Ex : 150 m²"
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium text-text-200">Référence cadastrale</label>
          <input
            type="text"
            name="reference_cadastrale"
            value={formData.reference_cadastrale}
            onChange={handleChange}
            className="w-full p-2.5 bg-layer-3 border rounded-lg text-text-100 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
          />
        </div>
      </div>'''

content = re.sub(
    r'<div className="grid grid-cols-1 md:grid-cols-2 gap-4">\s*\{\/\* Nom complet \*\/\}[\s\S]*?<\/textarea>\s*\{champsPreremplis\.includes\(\'adresse_residence\'\)[\s\S]*?<\/div>\s*<\/div>\s*<\/div>',
    jsx_fields,
    content
)

jsx_files = '''<div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <FileUploadField
          name="demande_regularisation_maire"
          label="Demande de régularisation adressée au Maire"
          description="Charger la demande"
        />
        <FileUploadField
          name="piece_identite_requerant"
          label="Photocopie de la pièce d'identité du requérant"
          description="Charger la CNI"
        />
        <FileUploadField
          name="acte_original_terrain"
          label="Acte original du terrain"
          description="Charger l'acte du terrain"
        />
      </div>'''

content = re.sub(
    r'<div className="grid grid-cols-1 md:grid-cols-2 gap-4">\s*<FileUploadField\s*name="cni"[\s\S]*?<\/div>',
    jsx_files,
    content
)

with open('frontend/src/components/citoyens/FormulaireRegularisation.jsx', 'w', encoding='utf-8') as f:
    f.write(content)
