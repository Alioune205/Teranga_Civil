@echo off
chcp 65001 >nul
echo =======================================================
echo       INITIALISATION AUTOMATIQUE DE L'IA NDIOGOYE
echo =======================================================
echo.

echo [1/3] Installation des nouvelles dependances...
call .\.venv\Scripts\activate.bat 2>nul
if %errorlevel% neq 0 (
    echo Attention: L'environnement virtuel .venv n'a pas ete trouve.
    echo Tentative d'installation globale...
)
pip install -r requirements.txt

echo.
echo [2/3] Verification de la cle API Gemini...
if not exist ".env" type nul > .env
findstr "GEMINI_API_KEY" .env >nul
if %errorlevel% neq 0 (
    echo.
    echo -----------------------------------------------------
    echo ⚠️ LA CLE API GEMINI EST MANQUANTE DANS .env !
    echo Demandez la cle API a votre collegue Lansana.
    set /p API_KEY="Collez la cle API ici et appuyez sur Entree : "
    echo.>> .env
    call echo GEMINI_API_KEY=%%API_KEY%%>> .env
    echo =^> Cle API enregistree avec succes dans .env !
    echo -----------------------------------------------------
) else (
    echo =^> La cle API est deja configuree dans .env.
)

echo.
echo [3/3] Reconstruction du cerveau de Ndiogoye (ChromaDB)...
python ingest_script.py

echo.
echo =======================================================
echo ✅ TOUT EST PRET ! LE BACKEND IA EST OPERATIONNEL !
echo =======================================================
