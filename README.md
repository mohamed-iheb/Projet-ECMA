# Projet ECMA - Résolution du tournées de véhicules Robuste

## Description
Ce projet vise à modéliser et résoudre une version robuste du Problème de Tournées de Véhicules (VRP - Vehicle Routing Problem), en tenant compte des incertitudes sur les distances.

## Auteurs
- Mohamed Iheb Kacem
- Aziz Mhadhbi

## Contenu du dépôt

- `data/` : Jeux de données pour les tests.
- `Pb_Statique_V0.jl` : Modélisation du problème statique.
- `Dualisation.jl` : Implémentation de la méthode de dualisation.
- `LazyCallback.jl` : Implémentation de la méthode B&C.
- `PlansCoupants.jl` : Algorithme de plans coupants.
- `heuristique.jl` : Implémentation des heuristiques.
- `Main.jl` : Script principal d'exécution et comparaison des 4 méthodes.
- `Rapport_Projet_ECMA_MHADHBI_KACEM.pdf` : Rapport détaillé du problème et des méthodes.

## Prérequis

### Environnement Julia
- Julia 1.5 ou plus récent
- Packages nécessaires :
  - `JuMP`
  - `Gurobi` ou `CPLEX`

## Exécution

1. Cloner le dépôt :
   ```bash
   git clone https://github.com/mohamed-iheb/Projet-ECMA.git
   cd Projet-ECMA
   ```

2. Vérifier la présence des fichiers dans `data/`.

3. Lancer l'exécution avec Julia :
   ```bash
   julia Main.jl
   ```

4. Etudier les performances et les visualiser avec Python :
   ```bash
   python tracage_Performances.py
   ```
